//
//  ESIMUtilities.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import Foundation
import UIKit
import CoreTelephony

/// Utility class for eSIM-related helper functions
public final class ESIMUtilities {
    
    // MARK: - Device Compatibility
    
    /// Checks if the current device supports eSIM functionality
    public static func checkESIMSupport() -> (isSupported: Bool, reason: String?) {
        // Check iOS version
        guard #available(iOS 12.0, *) else {
            return (false, "iOS 12.0 or later is required")
        }
        
        // Check general cellular plan support
        let provisioning = CTCellularPlanProvisioning()
        guard provisioning.supportsCellularPlan() else {
            return (false, "Device does not support cellular plans")
        }
        
        // Check embedded SIM support (iOS 16.0+)
        if #available(iOS 16.0, *) {
            let cellularPlanProvisioning = CTCellularPlanProvisioning()
            guard cellularPlanProvisioning.supportsEmbeddedSIM else {
                return (false, "Device does not support embedded SIM")
            }
        }
        
        // Check device model compatibility
        guard isDeviceModelCompatible() else {
            return (false, "Device model does not support eSIM")
        }
        
        return (true, nil)
    }
    
    /// Checks if the device model supports eSIM
    private static func isDeviceModelCompatible() -> Bool {
        let systemName = UIDevice.current.systemName
        
        // Only iPhones support eSIM (not iPads or iPods)
        guard systemName == "iPhone" else {
            return false
        }
        
        // Get device model identifier for more accurate checking
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        
        guard let modelCode = modelCode else {
            return false
        }
        
        // iPhone models that support eSIM (iPhone XS, XS Max, XR and later)
        let eSIMSupportedModels = [
            "iPhone11,2", // iPhone XS
            "iPhone11,4", // iPhone XS Max
            "iPhone11,6", // iPhone XS Max
            "iPhone11,8", // iPhone XR
            "iPhone12,1", // iPhone 11
            "iPhone12,3", // iPhone 11 Pro
            "iPhone12,5", // iPhone 11 Pro Max
            "iPhone13,1", // iPhone 12 mini
            "iPhone13,2", // iPhone 12
            "iPhone13,3", // iPhone 12 Pro
            "iPhone13,4", // iPhone 12 Pro Max
            "iPhone14,2", // iPhone 13 Pro
            "iPhone14,3", // iPhone 13 Pro Max
            "iPhone14,4", // iPhone 13 mini
            "iPhone14,5", // iPhone 13
            "iPhone14,6", // iPhone SE (3rd generation)
            "iPhone14,7", // iPhone 14
            "iPhone14,8", // iPhone 14 Plus
            "iPhone15,2", // iPhone 14 Pro
            "iPhone15,3", // iPhone 14 Pro Max
            "iPhone15,4", // iPhone 15
            "iPhone15,5", // iPhone 15 Plus
            "iPhone16,1", // iPhone 15 Pro
            "iPhone16,2", // iPhone 15 Pro Max
            "iPhone17,1", // iPhone 16
            "iPhone17,2", // iPhone 16 Plus
            "iPhone17,3", // iPhone 16 Pro
            "iPhone17,4", // iPhone 16 Pro Max
        ]
        
        return eSIMSupportedModels.contains(modelCode)
    }
    
    // MARK: - QR Code Generation
    
    /// Generates QR code string in LPA format
    public static func generateQRCodeString(
        smdpAddress: String,
        matchingID: String,
        confirmationCode: String? = nil
    ) -> String {
        var data = "LPA:1$\(smdpAddress)$\(matchingID)"
        if let confirmationCode = confirmationCode {
            data += "$\(confirmationCode)"
        }
        return data
    }
    
    /// Generates Apple Universal Link for eSIM installation (iOS 17.4+)
    @available(iOS 17.4, *)
    public static func generateUniversalLink(
        smdpAddress: String,
        matchingID: String,
        confirmationCode: String? = nil
    ) -> URL? {
        let qrCodeString = generateQRCodeString(
            smdpAddress: smdpAddress,
            matchingID: matchingID,
            confirmationCode: confirmationCode
        )
        
        let encodedData = qrCodeString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encodedData)")
    }
    
    // MARK: - Validation
    
    /// Validates SM-DP+ address format
    public static func validateSMDPAddress(_ address: String) -> Bool {
        // Basic validation - should be a valid hostname or IP
        let hostnameRegex = "^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?(\\.([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?))*$"
        let ipRegex = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        
        let hostnamePredicate = NSPredicate(format: "SELF MATCHES %@", hostnameRegex)
        let ipPredicate = NSPredicate(format: "SELF MATCHES %@", ipRegex)
        
        return hostnamePredicate.evaluate(with: address) || ipPredicate.evaluate(with: address)
    }
    
    /// Validates Matching ID format
    public static func validateMatchingID(_ matchingID: String) -> Bool {
        // Matching ID should be alphanumeric and not empty
        return !matchingID.isEmpty && matchingID.count >= 8
    }
    
    /// Validates EID format (if provided)
    public static func validateEID(_ eid: String) -> Bool {
        // EID should be 32 characters long and contain only hexadecimal characters
        let eidRegex = "^[0-9A-Fa-f]{32}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", eidRegex)
        return predicate.evaluate(with: eid)
    }
    
    /// Validates ICCID format (if provided)
    public static func validateICCID(_ iccid: String) -> Bool {
        // ICCID should be 19-20 digits
        let iccidRegex = "^[0-9]{19,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", iccidRegex)
        return predicate.evaluate(with: iccid)
    }
    
    // MARK: - Device Information
    
    /// Gets detailed device information
    public static func getDeviceInfo() -> (model: String, systemVersion: String, systemName: String) {
        let device = UIDevice.current
        return (
            model: device.model,
            systemVersion: device.systemVersion,
            systemName: device.systemName
        )
    }
    
    // MARK: - Settings Navigation
    
    /// Opens eSIM settings in the Settings app
    public static func openESIMSettings() {
        guard let settingsURL = URL(string: "App-Prefs:root=MOBILE_DATA_SETTINGS_ID") else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    /// Opens general Settings app
    public static func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Extensions

extension ESIMUtilities {
    /// Sample eSIM data for testing
    public static let sampleData = (
        smdpAddress: "rsp.truphone.com",
        matchingID: "JQ-209U6H-6I82J5",
        confirmationCode: nil as String?,
        eid: nil as String?,
        iccid: nil as String?
    )
    
    /// Common SM-DP+ addresses for testing
    public static let commonSMDPAddresses = [
        "rsp.truphone.com",
        "rsp.gsma.com",
        "rsp.airalo.com",
        "rsp.heyroamio.com"
    ]
}
