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
        return isSupported
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
    
    /// Get current eSIM profiles (if available)
    /// - Returns: Array of eSIM profile information
    @available(iOS 12.0, *)
    public func getCurrentESIMProfiles() -> [String] {
        // Note: This is a placeholder. Actual implementation would require
        // additional entitlements and APIs that may not be publicly available
        print("ESIMManager: Getting current eSIM profiles - requires additional entitlements")
        return []
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
