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
            guard CTCellularPlanProvisioning.supportsEmbeddedSIM() else {
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
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        
        // iPhone XR and later support eSIM
        if systemName == "iPhone" {
            // In a real implementation, you would check the specific device model
            // For now, we'll assume all modern iPhones support eSIM
            return true
        }
        
        return false
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
        confirmationCode: nil,
        eid: nil,
        iccid: nil
    )
    
    /// Common SM-DP+ addresses for testing
    public static let commonSMDPAddresses = [
        "rsp.truphone.com",
        "rsp.gsma.com",
        "rsp.airalo.com",
        "rsp.heyroamio.com"
    ]
}
