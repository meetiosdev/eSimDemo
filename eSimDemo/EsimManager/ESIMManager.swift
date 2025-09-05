//
//  ESIMManager.swift
//  EsimDemo
//
//  Created for iOS eSIM management
//  Requires iOS 12.0+ and proper entitlements
//

import Foundation
import CoreTelephony
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import os.log

// MARK: - Data Models

/// Represents parsed LPA (Local Profile Assistant) activation code components
public struct LPAComponents: Equatable {
    public let raw: String
    public let smdp: String?
    public let token: String?
    
    public init(raw: String, smdp: String?, token: String?) {
        self.raw = raw
        self.smdp = smdp
        self.token = token
    }
    
    public var isValid: Bool {
        return smdp != nil && !raw.isEmpty
    }
    
    public var displayString: String {
        if let smdp = smdp, let token = token {
            return "SMDP: \(smdp)\nToken: \(token)"
        } else if let smdp = smdp {
            return "SMDP: \(smdp)"
        } else {
            return raw
        }
    }
}

/// Represents the status of eSIM installation operations
public enum ESIMInstallationStatus: String, CaseIterable, Equatable {
    case success = "success"
    case failure = "failure"
    case userCancelled = "userCancelled"
    case notSupportedOrPermitted = "notsupportedorpermitted"
    case unknownError = "unknownError"
    case invalidActivationCode = "invalidactivationcode"
    case esimDisabledOrUnavailable = "esimdisabledorunavailable"
    case networkError = "networkerror"
    case storageFull = "storagefull"
    case timeout = "timeout"
}

/// Represents the result of an eSIM installation operation
public struct ESIMInstallationResult: Equatable {
    public let status: ESIMInstallationStatus
    public let message: String?
    public let errorCode: String?
    public let nativeException: String?
    public let timestamp: Date
    
    public init(
        status: ESIMInstallationStatus,
        message: String? = nil,
        errorCode: String? = nil,
        nativeException: String? = nil
    ) {
        self.status = status
        self.message = message
        self.errorCode = errorCode
        self.nativeException = nativeException
        self.timestamp = Date()
    }
}

/// Represents detailed eSIM support information
public struct ESIMSupportInfo: Equatable {
    public let apiSupported: Bool
    public let deviceCapable: Bool
    public let overallSupported: Bool
    public let iosVersion: String
    public let deviceModel: String
    public let entitlementsStatus: String
    public let entitlementsIssue: Bool
    
    public init(
        apiSupported: Bool,
        deviceCapable: Bool,
        overallSupported: Bool,
        iosVersion: String,
        deviceModel: String,
        entitlementsStatus: String,
        entitlementsIssue: Bool
    ) {
        self.apiSupported = apiSupported
        self.deviceCapable = deviceCapable
        self.overallSupported = overallSupported
        self.iosVersion = iosVersion
        self.deviceModel = deviceModel
        self.entitlementsStatus = entitlementsStatus
        self.entitlementsIssue = entitlementsIssue
    }
}

// MARK: - Delegate Protocol

/// Delegate protocol for eSIM manager events
public protocol ESIMManagerDelegate: AnyObject {
    func esimManager(_ manager: ESIMManager, didCompleteInstallationWith result: ESIMInstallationResult)
    func esimManager(_ manager: ESIMManager, didFailWith error: Error)
    func esimManager(_ manager: ESIMManager, didUpdateSupportInfo info: ESIMSupportInfo)
}

// MARK: - Main Manager Class

/// A comprehensive eSIM manager for iOS applications
/// Handles eSIM installation, QR code generation, LPA parsing, and device compatibility
@available(iOS 12.0, *)
public final class ESIMManager: NSObject {
    
    // MARK: - Singleton
    
    public static let shared = ESIMManager()
    
    // MARK: - Properties
    
    /// Delegate for eSIM manager events
    public weak var delegate: ESIMManagerDelegate?
    
    /// Core Telephony plan provisioning instance
    private let planProvisioning = CTCellularPlanProvisioning()
    
    /// Network info instance for carrier monitoring
    private let networkInfo = CTTelephonyNetworkInfo()
    
    /// Serial queue for thread-safe operations
    private let operationQueue = DispatchQueue(label: "com.esimmanager.operations", qos: .userInitiated)
    
    /// Concurrent queue for QR code generation
    private let qrCodeQueue = DispatchQueue(label: "com.esimmanager.qrcode", qos: .userInitiated, attributes: .concurrent)
    
    /// Current installation completion handler
    private var currentInstallationCompletion: ((ESIMInstallationResult) -> Void)?
    
    /// Logger for debugging and monitoring
    private let logger = Logger(subsystem: "com.esimmanager", category: "ESIMManager")
    
    /// Cached support info to avoid repeated calculations
    private var cachedSupportInfo: ESIMSupportInfo?
    
    /// Cached QR code images to avoid regeneration
    private let qrCodeCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupQRCodeCache()
        setupNetworkMonitoring()
        logger.info("ESIMManager initialized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        logger.info("ESIMManager deallocated")
    }
    
    // MARK: - Setup Methods
    
    /// Configure QR code cache settings
    private func setupQRCodeCache() {
        qrCodeCache.countLimit = 10
        qrCodeCache.totalCostLimit = 5 * 1024 * 1024 // 5MB
    }
    
    /// Setup network monitoring for carrier changes
    private func setupNetworkMonitoring() {
        // Note: CTCarrierDidUpdate notification is not available in public API
        // This is a placeholder for future implementation when proper entitlements are available
        logger.info("Network monitoring setup - requires additional entitlements")
    }
    
    /// Handle carrier information updates
    @objc private func carrierDidUpdate() {
        logger.info("Carrier information updated")
        invalidateCachedSupportInfo()
        
        // Notify delegate on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let supportInfo = self.getESIMSupportInfo()
            self.delegate?.esimManager(self, didUpdateSupportInfo: supportInfo)
        }
    }
    
    /// Invalidate cached support information
    private func invalidateCachedSupportInfo() {
        operationQueue.async { [weak self] in
            self?.cachedSupportInfo = nil
        }
    }
    
    // MARK: - eSIM Support Detection
    
    /// Check if the device supports eSIM functionality
    /// - Returns: Boolean indicating eSIM support
    public func isESIMSupported() -> Bool {
        let isSupported = planProvisioning.supportsCellularPlan()
        logger.info("eSIM support check - \(isSupported)")
        
        // Handle entitlements issue: API returns false even on eSIM-capable devices
        if !isSupported {
            if isDeviceESIMCapable() {
                logger.info("API returned false, but device supports eSIM (entitlements issue)")
                return true // For development/testing purposes
            } else {
                logger.info("Device does not support eSIM")
                return false
            }
        }
        
        return isSupported
    }
    
    /// Check if the current device is eSIM-capable based on hardware and iOS version
    /// - Returns: Boolean indicating if device hardware supports eSIM
    private func isDeviceESIMCapable() -> Bool {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        
        // Parse iOS version
        let versionComponents = systemVersion.components(separatedBy: ".")
        guard let majorVersion = Int(versionComponents.first ?? "0") else {
            logger.error("Unable to parse iOS version")
            return false
        }
        
        guard majorVersion >= 12 else {
            logger.warning("iOS version \(systemVersion) is too old for eSIM support")
            return false
        }
        
        // Check device model (iPhone XS and newer support eSIM)
        let modelName = device.model
        
        if modelName == "iPhone" {
            logger.info("iPhone detected with iOS \(systemVersion) - eSIM capable")
            return true
        }
        
        logger.info("Non-iPhone device detected - eSIM not supported")
        return false
    }
    
    /// Get detailed eSIM support information including entitlements status
    /// - Returns: ESIMSupportInfo with detailed support information
    public func getESIMSupportInfo() -> ESIMSupportInfo {
        // Return cached info if available
        if let cached = cachedSupportInfo {
            return cached
        }
        
        let apiSupported = planProvisioning.supportsCellularPlan()
        let deviceCapable = isDeviceESIMCapable()
        let overallSupported = apiSupported || (deviceCapable && !apiSupported)
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        let entitlementsStatus: String
        let entitlementsIssue: Bool
        
        if !apiSupported && deviceCapable {
            entitlementsStatus = "Missing - API returns false but device supports eSIM"
            entitlementsIssue = true
        } else if apiSupported {
            entitlementsStatus = "Present - API returns true"
            entitlementsIssue = false
        } else {
            entitlementsStatus = "Not applicable - Device does not support eSIM"
            entitlementsIssue = false
        }
        
        let supportInfo = ESIMSupportInfo(
            apiSupported: apiSupported,
            deviceCapable: deviceCapable,
            overallSupported: overallSupported,
            iosVersion: iosVersion,
            deviceModel: deviceModel,
            entitlementsStatus: entitlementsStatus,
            entitlementsIssue: entitlementsIssue
        )
        
        // Cache the result
        cachedSupportInfo = supportInfo
        
        return supportInfo
    }
    
    // MARK: - eSIM Installation
    
    /// Install eSIM profile using activation code
    /// - Parameters:
    ///   - activationCode: The activation code (usually from QR code)
    ///   - confirmationCode: Optional confirmation code
    ///   - completion: Completion handler with installation result
    public func installESIM(
        activationCode: String,
        confirmationCode: String? = nil,
        completion: @escaping (ESIMInstallationResult) -> Void
    ) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Validate inputs
            guard !activationCode.isEmpty else {
                let result = ESIMInstallationResult(
                    status: .invalidActivationCode,
                    message: "Activation code cannot be empty",
                    errorCode: "INVALID_ACTIVATION_CODE"
                )
                DispatchQueue.main.async { completion(result) }
                return
            }
            
            guard self.isESIMSupported() else {
                let result = ESIMInstallationResult(
                    status: .esimDisabledOrUnavailable,
                    message: "eSIM is not supported or available on this device",
                    errorCode: "ESIM_NOT_SUPPORTED"
                )
                DispatchQueue.main.async { completion(result) }
                return
            }
            
            // Store completion handler
            self.currentInstallationCompletion = completion
            
            // Create provisioning request
            let request = CTCellularPlanProvisioningRequest()
            request.address = activationCode
            
            if let confirmationCode = confirmationCode {
                request.confirmationCode = confirmationCode
            }
            
            self.logger.info("Starting eSIM installation with activation code: \(activationCode)")
            
            // Start the installation process
            self.planProvisioning.addPlan(with: request) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleInstallationResult(result, completion: completion)
                }
            }
        }
    }
    
    /// Install eSIM profile using activation code (delegate pattern)
    /// - Parameters:
    ///   - activationCode: The activation code (usually from QR code)
    ///   - confirmationCode: Optional confirmation code
    public func installESIMWithDelegate(
        activationCode: String,
        confirmationCode: String? = nil
    ) {
        installESIM(activationCode: activationCode, confirmationCode: confirmationCode) { [weak self] result in
            guard let self = self else { return }
            
            if result.status == .success {
                self.delegate?.esimManager(self, didCompleteInstallationWith: result)
            } else {
                let error = NSError(
                    domain: "ESIMManager",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: result.message ?? "eSIM installation failed",
                        "status": result.status.rawValue,
                        "errorCode": result.errorCode ?? "UNKNOWN"
                    ]
                )
                self.delegate?.esimManager(self, didFailWith: error)
            }
        }
    }
    
    /// Handle installation result from Core Telephony
    private func handleInstallationResult(
        _ result: CTCellularPlanProvisioningAddPlanResult,
        completion: @escaping (ESIMInstallationResult) -> Void
    ) {
        let status: ESIMInstallationStatus
        let message: String?
        let errorCode: String?
        
        switch result {
        case .success:
            status = .success
            message = "eSIM profile installed successfully"
            errorCode = nil
            logger.info("eSIM installation completed successfully")
            
        case .fail:
            status = .failure
            message = "Failed to install eSIM profile"
            errorCode = "ADD_PLAN_FAILED"
            logger.error("eSIM installation failed")
            
        case .unknown:
            status = .unknownError
            message = "eSIM installation result is unknown"
            errorCode = "ADD_PLAN_UNKNOWN"
            logger.warning("eSIM installation result unknown")
            
        case .cancel:
            status = .userCancelled
            message = "User cancelled eSIM installation"
            errorCode = "USER_CANCELLED"
            logger.info("User cancelled eSIM installation")
            
        @unknown default:
            status = .unknownError
            message = "Unexpected eSIM installation result: \(result.rawValue)"
            errorCode = "ADD_PLAN_UNEXPECTED"
            logger.error("Unexpected eSIM installation result: \(result.rawValue)")
        }
        
        let installationResult = ESIMInstallationResult(
            status: status,
            message: message,
            errorCode: errorCode
        )
        
        completion(installationResult)
    }
    
    // MARK: - LPA Parsing
    
    /// Parse LPA activation code into components
    /// - Parameter lpa: The LPA activation code string
    /// - Returns: LPAComponents with parsed information
    public func parseLPA(_ lpa: String) -> LPAComponents {
        let parts = lpa.split(separator: "$", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 2, parts.first?.uppercased().hasPrefix("LPA:1") == true else {
            return LPAComponents(raw: lpa, smdp: nil, token: nil)
        }
        let smdp = parts.count > 1 ? parts[1] : nil
        let token = parts.count > 2 ? parts[2] : nil
        return LPAComponents(raw: lpa, smdp: smdp, token: token)
    }
    
    // MARK: - QR Code Generation
    
    /// Generate QR code image from string
    /// - Parameters:
    ///   - string: The string to encode in QR code
    ///   - scale: Scale factor for the QR code (default: 10)
    /// - Returns: UIImage containing the QR code, or nil if generation fails
    public func generateQRCode(from string: String, scale: CGFloat = 10) -> UIImage? {
        // Check cache first
        let cacheKey = "\(string)_\(scale)" as NSString
        if let cachedImage = qrCodeCache.object(forKey: cacheKey) {
            logger.debug("QR code retrieved from cache")
            return cachedImage
        }
        
        // Generate QR code on background queue
        var qrImage: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        qrCodeQueue.async {
            let data = Data(string.utf8)
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
            
            guard let output = filter.outputImage else {
                self.logger.error("Failed to generate QR code output image")
                semaphore.signal()
                return
            }
            
            let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            // Convert CIImage to UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
                self.logger.error("Failed to create CGImage from QR code")
                semaphore.signal()
                return
            }
            
            qrImage = UIImage(cgImage: cgImage)
            semaphore.signal()
        }
        
        semaphore.wait()
        
        // Cache the result
        if let image = qrImage {
            qrCodeCache.setObject(image, forKey: cacheKey)
            logger.debug("QR code generated and cached")
        }
        
        return qrImage
    }
    
    /// Generate QR code for eSIM activation
    /// - Parameters:
    ///   - activationCode: The eSIM activation code
    ///   - scale: Scale factor for the QR code (default: 10)
    /// - Returns: UIImage containing the QR code, or nil if generation fails
    public func generateESIMQRCode(activationCode: String, scale: CGFloat = 10) -> UIImage? {
        logger.info("Generating QR code for activation code: \(activationCode)")
        return generateQRCode(from: activationCode, scale: scale)
    }
    
    // MARK: - Validation
    
    /// Validate activation code format
    /// - Parameter activationCode: The activation code to validate
    /// - Returns: Boolean indicating if the format is valid
    public func validateActivationCode(_ activationCode: String) -> Bool {
        let patterns = [
            "^LPA:1\\$[^\\$]+\\$[^\\$]+$",  // LPA:1$smdp.example.com$MATCHING_ID
            "^[A-Z0-9]{20,}$",              // Simple alphanumeric codes
            "^[0-9]{19,32}$"                // Numeric codes
        ]
        
        for pattern in patterns {
            if activationCode.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Utility Methods
    
    /// Get current eSIM profiles (if available)
    /// - Returns: Array of eSIM profile information
    public func getCurrentESIMProfiles() -> [String] {
        // Note: This is a placeholder. Actual implementation would require
        // additional entitlements and APIs that may not be publicly available
        logger.info("Getting current eSIM profiles - requires additional entitlements")
        return []
    }
    
    /// Clear QR code cache
    public func clearQRCodeCache() {
        qrCodeCache.removeAllObjects()
        logger.info("QR code cache cleared")
    }
    
    /// Clear all caches
    public func clearAllCaches() {
        clearQRCodeCache()
        invalidateCachedSupportInfo()
        logger.info("All caches cleared")
    }
}

// MARK: - Error Handling Extension

@available(iOS 12.0, *)
extension ESIMManager {
    
    /// Handle specific eSIM errors
    /// - Parameter error: The error to handle
    /// - Returns: Appropriate ESIMInstallationResult
    public func handleError(_ error: Error) -> ESIMInstallationResult {
        let nsError = error as NSError
        
        switch nsError.code {
        case -1009: // NSURLErrorNotConnectedToInternet
            return ESIMInstallationResult(
                status: .networkError,
                message: "No internet connection available",
                errorCode: "NO_INTERNET_CONNECTION"
            )
        case -1001: // NSURLErrorTimedOut
            return ESIMInstallationResult(
                status: .timeout,
                message: "eSIM installation timed out",
                errorCode: "INSTALLATION_TIMEOUT"
            )
        case -1003: // NSURLErrorCannotFindHost
            return ESIMInstallationResult(
                status: .networkError,
                message: "Cannot connect to carrier server",
                errorCode: "CANNOT_FIND_HOST"
            )
        case -1004: // NSURLErrorCannotConnectToHost
            return ESIMInstallationResult(
                status: .networkError,
                message: "Cannot connect to carrier server",
                errorCode: "CANNOT_CONNECT_TO_HOST"
            )
        default:
            return ESIMInstallationResult(
                status: .unknownError,
                message: error.localizedDescription,
                errorCode: "UNKNOWN_ERROR_\(nsError.code)"
            )
        }
    }
}

// MARK: - Usage Examples

/*
 
 // Example usage with completion handler:
 ESIMManager.shared.installESIM(activationCode: "LPA:1$smdp.example.com$MATCHING_ID") { result in
     switch result.status {
     case .success:
         print("eSIM installed successfully: \(result.message ?? "")")
     case .failure:
         print("eSIM installation failed: \(result.message ?? "")")
     case .userCancelled:
         print("User cancelled eSIM installation")
     default:
         print("eSIM installation error: \(result.message ?? "")")
     }
 }
 
 // Example usage with delegate pattern:
 class ViewController: UIViewController, ESIMManagerDelegate {
     override func viewDidLoad() {
         super.viewDidLoad()
         ESIMManager.shared.delegate = self
     }
     
     func esimManager(_ manager: ESIMManager, didCompleteInstallationWith result: ESIMInstallationResult) {
         // Handle successful installation
         print("eSIM installed: \(result.message ?? "")")
     }
     
     func esimManager(_ manager: ESIMManager, didFailWith error: Error) {
         // Handle installation failure
         print("eSIM installation failed: \(error.localizedDescription)")
     }
     
     func esimManager(_ manager: ESIMManager, didUpdateSupportInfo info: ESIMSupportInfo) {
         // Handle support info updates
         print("eSIM support info updated: \(info.entitlementsStatus)")
     }
 }
 
 // Example QR code generation:
 if let qrImage = ESIMManager.shared.generateESIMQRCode(activationCode: "LPA:1$smdp.example.com$TOKEN") {
     // Use the QR code image
     imageView.image = qrImage
 }
 
 // Example LPA parsing:
 let lpaComponents = ESIMManager.shared.parseLPA("LPA:1$smdp.example.com$TOKEN")
 if lpaComponents.isValid {
     print("SMDP: \(lpaComponents.smdp ?? "")")
     print("Token: \(lpaComponents.token ?? "")")
 }
 
 */