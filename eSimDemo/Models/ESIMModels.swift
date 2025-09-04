//
//  ESIMModels.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import Foundation
import CoreTelephony

// MARK: - eSIM Provisioning Models

/// Represents the result of an eSIM provisioning operation
@Observable
public final class ESIMProvisioningResult {
    public let isSuccess: Bool
    public let message: String
    public let error: ESIMError?
    
    public init(isSuccess: Bool, message: String, error: ESIMError? = nil) {
        self.isSuccess = isSuccess
        self.message = message
        self.error = error
    }
}

/// Represents an eSIM provisioning request
public struct ESIMProvisioningRequest {
    public let smdpAddress: String
    public let matchingID: String
    public let confirmationCode: String?
    public let eid: String?
    public let iccid: String?
    
    public init(
        smdpAddress: String,
        matchingID: String,
        confirmationCode: String? = nil,
        eid: String? = nil,
        iccid: String? = nil
    ) {
        self.smdpAddress = smdpAddress
        self.matchingID = matchingID
        self.confirmationCode = confirmationCode
        self.eid = eid
        self.iccid = iccid
    }
}

/// Represents device eSIM compatibility status
@Observable
public final class ESIMCompatibilityStatus {
    public let isSupported: Bool
    public let deviceModel: String
    public let iosVersion: String
    public let reason: String?
    
    public init(isSupported: Bool, deviceModel: String, iosVersion: String, reason: String? = nil) {
        self.isSupported = isSupported
        self.deviceModel = deviceModel
        self.iosVersion = iosVersion
        self.reason = reason
    }
}

/// Represents eSIM provisioning state
@Observable
public final class ESIMProvisioningState {
    public var isProvisioning: Bool = false
    public var currentStep: ESIMProvisioningStep = .idle
    public var progress: Double = 0.0
    public var result: ESIMProvisioningResult?
    
    public init() {}
}

/// Represents different steps in eSIM provisioning process
public enum ESIMProvisioningStep: String, CaseIterable {
    case idle = "Ready"
    case checkingCompatibility = "Checking Device Compatibility"
    case validatingRequest = "Validating Request"
    case provisioning = "Installing eSIM Profile"
    case completed = "Installation Complete"
    case failed = "Installation Failed"
    
    public var displayName: String {
        return self.rawValue
    }
}

// MARK: - Error Handling

/// Custom error types for eSIM operations
public enum ESIMError: LocalizedError, Equatable {
    case deviceNotSupported
    case invalidRequest
    case invalidSMDPAddress
    case invalidMatchingID
    case invalidEID
    case invalidICCID
    case networkError(String)
    case provisioningFailed(String)
    case entitlementRequired
    case unsupportedIOSVersion
    case cellularPlanNotSupported
    case embeddedSIMNotSupported
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "This device does not support eSIM functionality. eSIM is supported on iPhone XS, XS Max, XR and later models."
        case .invalidRequest:
            return "Invalid provisioning request parameters"
        case .invalidSMDPAddress:
            return "Invalid SM-DP+ address format. Please enter a valid hostname or IP address."
        case .invalidMatchingID:
            return "Invalid Matching ID format. Please enter a valid activation code (minimum 8 characters)."
        case .invalidEID:
            return "Invalid EID format. EID must be 32 hexadecimal characters."
        case .invalidICCID:
            return "Invalid ICCID format. ICCID must be 19-20 digits."
        case .networkError(let message):
            return "Network error: \(message)"
        case .provisioningFailed(let message):
            return "eSIM provisioning failed: \(message)"
        case .entitlementRequired:
            return "eSIM entitlement required. This app needs special permission from Apple to provision eSIM profiles directly. Contact Apple Developer Support for entitlement approval."
        case .unsupportedIOSVersion:
            return "iOS 12.0 or later is required for eSIM functionality"
        case .cellularPlanNotSupported:
            return "This device does not support cellular plans"
        case .embeddedSIMNotSupported:
            return "This device does not support embedded SIM functionality"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .deviceNotSupported:
            return "Please use a device that supports eSIM (iPhone XS or later) or generate a QR code for manual activation."
        case .invalidSMDPAddress:
            return "Check the SM-DP+ address with your carrier. It should be a valid hostname like 'rsp.truphone.com' or an IP address."
        case .invalidMatchingID:
            return "Verify the activation code with your carrier. It should be at least 8 characters long."
        case .invalidEID:
            return "EID should be exactly 32 hexadecimal characters (0-9, A-F). Leave empty if not provided by your carrier."
        case .invalidICCID:
            return "ICCID should be 19-20 digits. Leave empty if not provided by your carrier."
        case .entitlementRequired:
            return "Use the QR code generation feature to manually activate the eSIM through Settings > Cellular > Add Cellular Plan."
        case .cellularPlanNotSupported:
            return "This device cannot manage cellular plans. Please use a different device."
        case .embeddedSIMNotSupported:
            return "This device does not support embedded SIM cards. Please use a device with eSIM capability."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Carrier Information

/// Represents carrier information for eSIM provisioning
public struct CarrierInfo {
    public let mcc: String
    public let mnc: String
    public let name: String
    public let gid1: String?
    public let gid2: String?
    
    public init(mcc: String, mnc: String, name: String, gid1: String? = nil, gid2: String? = nil) {
        self.mcc = mcc
        self.mnc = mnc
        self.name = name
        self.gid1 = gid1
        self.gid2 = gid2
    }
}

// MARK: - QR Code Models

/// Represents QR code data for eSIM activation
public struct ESIMQRCodeData {
    public let smdpAddress: String
    public let matchingID: String
    public let confirmationCode: String?
    
    public init(smdpAddress: String, matchingID: String, confirmationCode: String? = nil) {
        self.smdpAddress = smdpAddress
        self.matchingID = matchingID
        self.confirmationCode = confirmationCode
    }
    
    /// Generates the QR code string in LPA format
    public var qrCodeString: String {
        var data = "LPA:1$\(smdpAddress)$\(matchingID)"
        if let confirmationCode = confirmationCode {
            data += "$\(confirmationCode)"
        }
        return data
    }
    
    /// Generates Apple Universal Link for eSIM installation (iOS 17.4+)
    public var universalLink: URL? {
        let encodedData = qrCodeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encodedData)")
    }
}