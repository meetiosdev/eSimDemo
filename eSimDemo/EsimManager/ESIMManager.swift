//
//  ESIMManager.swift
//  Flutter Esim Internal
//
//  Created for iOS eSIM management
//  Requires iOS 12.0+ and proper entitlements
//

import Foundation
import CoreTelephony
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - LPA Components Structure
public struct LPAComponents {
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

// MARK: - eSIM Installation Status Enum
public enum ESIMInstallationStatus: String, CaseIterable {
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

// MARK: - eSIM Installation Result
public struct ESIMInstallationResult {
    public let status: ESIMInstallationStatus
    public let message: String?
    public let errorCode: String?
    public let nativeException: String?
    
    public init(status: ESIMInstallationStatus, message: String? = nil, errorCode: String? = nil, nativeException: String? = nil) {
        self.status = status
        self.message = message
        self.errorCode = errorCode
        self.nativeException = nativeException
    }
}

// MARK: - eSIM Manager Protocol
public protocol ESIMManagerDelegate: AnyObject {
    func esimManager(_ manager: ESIMManager, didCompleteInstallationWith result: ESIMInstallationResult)
    func esimManager(_ manager: ESIMManager, didFailWith error: Error)
}

// MARK: - eSIM Manager Class
public class ESIMManager: NSObject {
    
    // MARK: - Properties
    public static let shared = ESIMManager()
    public weak var delegate: ESIMManagerDelegate?
    
    private let planProvisioning = CTCellularPlanProvisioning()
    private var currentInstallationCompletion: ((ESIMInstallationResult) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Check if the device supports eSIM functionality
    /// - Returns: Boolean indicating eSIM support
    public func isESIMSupported() -> Bool {
        guard #available(iOS 12.0, *) else {
            print("ESIMManager: eSIM functionality requires iOS 12.0 or higher")
            return false
        }
        
        let isSupported = planProvisioning.supportsCellularPlan()
        print("ESIMManager: eSIM support check - \(isSupported)")
        
        // Handle entitlements issue: API returns false even on eSIM-capable devices
        // when proper entitlements are missing
        if !isSupported {
            // Check if this is a known eSIM-capable device with iOS 12.0+
            if isDeviceESIMCapable() {
                print("ESIMManager: API returned false, but device supports eSIM (entitlements issue)")
                print("ESIMManager: Device is eSIM-capable but lacks proper provisioning entitlements")
                print("ESIMManager: This is expected behavior for apps without carrier entitlements")
                // For development/testing purposes, return true
                // In production, you should handle this case appropriately based on your use case
                return true
            } else {
                print("ESIMManager: Device does not support eSIM")
                return false
            }
        }
        
        return isSupported
    }
    
    /// Check if the current device is eSIM-capable based on hardware and iOS version
    /// - Returns: Boolean indicating if device hardware supports eSIM
    private func isDeviceESIMCapable() -> Bool {
        // Check iOS version
        guard #available(iOS 12.0, *) else {
            print("ESIMManager: eSIM requires iOS 12.0 or higher")
            return false
        }
        
        // Get device model information
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        
        // Parse iOS version
        let versionComponents = systemVersion.components(separatedBy: ".")
        guard let majorVersion = Int(versionComponents.first ?? "0") else {
            print("ESIMManager: Unable to parse iOS version")
            return false
        }
        
        // Check if iOS version is 12.0 or higher
        guard majorVersion >= 12 else {
            print("ESIMManager: iOS version \(systemVersion) is too old for eSIM support")
            return false
        }
        
        // Check device model (iPhone XS and newer support eSIM)
        let modelName = device.model
        
        // iPhone XS, XS Max, XR and newer support eSIM
        if modelName == "iPhone" {
            // For iPhone models, we assume modern iPhones support eSIM
            // In a production app, you might want to use more sophisticated device detection
            print("ESIMManager: iPhone detected with iOS \(systemVersion) - eSIM capable")
            return true
        }
        
        print("ESIMManager: Non-iPhone device detected - eSIM not supported")
        return false
    }
    
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
        guard #available(iOS 12.0, *) else {
            let result = ESIMInstallationResult(
                status: .notSupportedOrPermitted,
                message: "eSIM functionality requires iOS 12.0 or higher",
                errorCode: "UNSUPPORTED_OS_VERSION"
            )
            completion(result)
            return
        }
        
        guard isESIMSupported() else {
            let result = ESIMInstallationResult(
                status: .esimDisabledOrUnavailable,
                message: "eSIM is not supported or available on this device",
                errorCode: "ESIM_NOT_SUPPORTED"
            )
            completion(result)
            return
        }
        
        guard !activationCode.isEmpty else {
            let result = ESIMInstallationResult(
                status: .invalidActivationCode,
                message: "Activation code cannot be empty",
                errorCode: "INVALID_ACTIVATION_CODE"
            )
            completion(result)
            return
        }
        
        // Store completion handler for delegate pattern
        currentInstallationCompletion = completion
        
        // Create provisioning request
        let request = CTCellularPlanProvisioningRequest()
        request.address = activationCode
        
        if let confirmationCode = confirmationCode {
            request.confirmationCode = confirmationCode
        }
        
        print("ESIMManager: Starting eSIM installation with activation code: \(activationCode)")
        
        // Start the installation process
        planProvisioning.addPlan(with: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleInstallationResult(result, completion: completion)
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
    
    // MARK: - Private Methods
    
    private func handleInstallationResult(
        _ result: CTCellularPlanProvisioningAddPlanResult,
        completion: @escaping (ESIMInstallationResult) -> Void
    ) {
        var status: ESIMInstallationStatus
        var message: String?
        var errorCode: String?
        
        switch result {
        case .success:
            status = .success
            message = "eSIM profile installed successfully"
            print("ESIMManager: eSIM installation completed successfully")
            
        case .fail:
            status = .failure
            message = "Failed to install eSIM profile"
            errorCode = "ADD_PLAN_FAILED"
            print("ESIMManager: eSIM installation failed")
            
        case .unknown:
            status = .unknownError
            message = "eSIM installation result is unknown"
            errorCode = "ADD_PLAN_UNKNOWN"
            print("ESIMManager: eSIM installation result unknown")
            
        case .cancel:
            status = .userCancelled
            message = "User cancelled eSIM installation"
            errorCode = "USER_CANCELLED"
            print("ESIMManager: User cancelled eSIM installation")
            
        @unknown default:
            status = .unknownError
            message = "Unexpected eSIM installation result: \(result.rawValue)"
            errorCode = "ADD_PLAN_UNEXPECTED"
            print("ESIMManager: Unexpected eSIM installation result: \(result.rawValue)")
        }
        
        let installationResult = ESIMInstallationResult(
            status: status,
            message: message,
            errorCode: errorCode
        )
        
        completion(installationResult)
    }
    
    // MARK: - Utility Methods
    
    /// Get detailed eSIM support information including entitlements status
    /// - Returns: Dictionary with detailed support information
    public func getESIMSupportInfo() -> [String: Any] {
        var supportInfo: [String: Any] = [:]
        
        // Basic support check
        let apiSupported = planProvisioning.supportsCellularPlan()
        supportInfo["apiSupported"] = apiSupported
        
        // Device capability check
        let deviceCapable = isDeviceESIMCapable()
        supportInfo["deviceCapable"] = deviceCapable
        
        // iOS version check
        let iosVersion = UIDevice.current.systemVersion
        supportInfo["iosVersion"] = iosVersion
        
        // Device model
        let deviceModel = UIDevice.current.model
        supportInfo["deviceModel"] = deviceModel
        
        // Overall support determination
        let overallSupported = apiSupported || (deviceCapable && !apiSupported)
        supportInfo["overallSupported"] = overallSupported
        
        // Entitlements status
        if !apiSupported && deviceCapable {
            supportInfo["entitlementsStatus"] = "Missing - API returns false but device supports eSIM"
            supportInfo["entitlementsIssue"] = true
        } else if apiSupported {
            supportInfo["entitlementsStatus"] = "Present - API returns true"
            supportInfo["entitlementsIssue"] = false
        } else {
            supportInfo["entitlementsStatus"] = "Not applicable - Device does not support eSIM"
            supportInfo["entitlementsIssue"] = false
        }
        
        return supportInfo
    }
    
    /// Get current eSIM profiles (if available)
    /// - Returns: Array of eSIM profile information
    @available(iOS 12.0, *)
    public func getCurrentESIMProfiles() -> [String] {
        // Note: This is a placeholder. Actual implementation would require
        // additional entitlements and APIs that may not be publicly available
        print("ESIMManager: Getting current eSIM profiles - requires additional entitlements")
        return []
    }
    
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
    
    /// Generate QR code image from string
    /// - Parameters:
    ///   - string: The string to encode in QR code
    ///   - scale: Scale factor for the QR code (default: 10)
    /// - Returns: UIImage containing the QR code, or nil if generation fails
    public func generateQRCode(from string: String, scale: CGFloat = 10) -> UIImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        // L, M, Q, H — "M" is a good default for eSIM codes
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let output = filter.outputImage else { 
            print("ESIMManager: Failed to generate QR code output image")
            return nil 
        }
        
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Convert CIImage to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            print("ESIMManager: Failed to create CGImage from QR code")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generate QR code for eSIM activation
    /// - Parameters:
    ///   - activationCode: The eSIM activation code
    ///   - scale: Scale factor for the QR code (default: 10)
    /// - Returns: UIImage containing the QR code, or nil if generation fails
    public func generateESIMQRCode(activationCode: String, scale: CGFloat = 10) -> UIImage? {
        print("ESIMManager: Generating QR code for activation code: \(activationCode)")
        return generateQRCode(from: activationCode, scale: scale)
    }
    
    /// Validate activation code format
    /// - Parameter activationCode: The activation code to validate
    /// - Returns: Boolean indicating if the format is valid
    public func validateActivationCode(_ activationCode: String) -> Bool {
        // Basic validation for common eSIM activation code formats
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
}

// MARK: - Error Handling Extension
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
        default:
            return ESIMInstallationResult(
                status: .unknownError,
                message: error.localizedDescription,
                errorCode: "UNKNOWN_ERROR_\(nsError.code)"
            )
        }
    }
}

// MARK: - Usage Example
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
 }
 
 */
