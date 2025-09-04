//
//  ESIMService.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import Foundation
import CoreTelephony
import UIKit

/// Service responsible for eSIM operations and device compatibility checks
@MainActor
public final class ESIMService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var compatibilityStatus: ESIMCompatibilityStatus
    @Published public private(set) var provisioningState: ESIMProvisioningState
    @Published public private(set) var isEntitlementAvailable: Bool = false
    
    // MARK: - Private Properties
    
    private let cellularPlanProvisioning = CTCellularPlanProvisioning()
    
    // MARK: - Initialization
    
    public init() {
        self.compatibilityStatus = ESIMCompatibilityStatus(
            isSupported: false,
            deviceModel: UIDevice.current.model,
            iosVersion: UIDevice.current.systemVersion
        )
        self.provisioningState = ESIMProvisioningState()
        
        Task {
            await checkDeviceCompatibility()
            await checkEntitlementAvailability()
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if the device supports eSIM functionality
    public func checkDeviceCompatibility() async {
        let deviceModel = UIDevice.current.model
        let iosVersion = UIDevice.current.systemVersion
        
        // Check iOS version requirement
        guard #available(iOS 12.0, *) else {
            compatibilityStatus = ESIMCompatibilityStatus(
                isSupported: false,
                deviceModel: deviceModel,
                iosVersion: iosVersion,
                reason: "iOS 12.0 or later is required"
            )
            return
        }
        
        // Check general cellular plan support
        let supportsCellularPlan = cellularPlanProvisioning.supportsCellularPlan()
        
        // Check embedded SIM support (iOS 16.0+)
        var supportsEmbeddedSIM = true
        if #available(iOS 16.0, *) {
            supportsEmbeddedSIM = CTCellularPlanProvisioning.supportsEmbeddedSIM()
        }
        
        // Check device model compatibility
        let isDeviceCompatible = checkDeviceModelCompatibility()
        
        let isSupported = supportsCellularPlan && supportsEmbeddedSIM && isDeviceCompatible
        
        let reason: String? = isSupported ? nil : {
            if !supportsCellularPlan {
                return "Device does not support cellular plans"
            } else if !supportsEmbeddedSIM {
                return "Device does not support embedded SIM"
            } else if !isDeviceCompatible {
                return "Device model does not support eSIM"
            }
            return "Unknown compatibility issue"
        }()
        
        compatibilityStatus = ESIMCompatibilityStatus(
            isSupported: isSupported,
            deviceModel: deviceModel,
            iosVersion: iosVersion,
            reason: reason
        )
    }
    
    /// Provisions an eSIM profile using the provided request
    public func provisionESIM(with request: ESIMProvisioningRequest) async {
        guard compatibilityStatus.isSupported else {
            provisioningState.result = ESIMProvisioningResult(
                isSuccess: false,
                message: "Device does not support eSIM",
                error: .deviceNotSupported
            )
            return
        }
        
        guard #available(iOS 12.0, *) else {
            provisioningState.result = ESIMProvisioningResult(
                isSuccess: false,
                message: "iOS 12.0 or later is required",
                error: .unsupportedIOSVersion
            )
            return
        }
        
        // Update provisioning state
        provisioningState.isProvisioning = true
        provisioningState.currentStep = .checkingCompatibility
        provisioningState.progress = 0.1
        
        do {
            // Validate request
            provisioningState.currentStep = .validatingRequest
            provisioningState.progress = 0.2
            
            try validateRequest(request)
            
            // Create CoreTelephony request
            let ctRequest = CTCellularPlanProvisioningRequest()
            ctRequest.address = request.smdpAddress
            ctRequest.matchingID = request.matchingID
            ctRequest.confirmationCode = request.confirmationCode
            ctRequest.eid = request.eid
            ctRequest.iccid = request.iccid
            
            // Start provisioning
            provisioningState.currentStep = .provisioning
            provisioningState.progress = 0.5
            
            let result = await performProvisioning(with: ctRequest)
            
            // Update final state
            provisioningState.isProvisioning = false
            provisioningState.progress = 1.0
            provisioningState.currentStep = result.isSuccess ? .completed : .failed
            provisioningState.result = result
            
        } catch {
            provisioningState.isProvisioning = false
            provisioningState.progress = 0.0
            provisioningState.currentStep = .failed
            provisioningState.result = ESIMProvisioningResult(
                isSuccess: false,
                message: error.localizedDescription,
                error: error as? ESIMError ?? .unknown(error.localizedDescription)
            )
        }
    }
    
    /// Generates QR code data for eSIM activation
    public func generateQRCodeData(from request: ESIMProvisioningRequest) -> ESIMQRCodeData {
        return ESIMQRCodeData(
            smdpAddress: request.smdpAddress,
            matchingID: request.matchingID,
            confirmationCode: request.confirmationCode
        )
    }
    
    /// Opens eSIM settings in the Settings app
    public func openESIMSettings() {
        guard let settingsURL = URL(string: "App-Prefs:root=MOBILE_DATA_SETTINGS_ID") else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    /// Opens Apple's eSIM setup using Universal Link (iOS 17.4+)
    @available(iOS 17.4, *)
    public func openESIMUniversalLink(with qrCodeData: ESIMQRCodeData) {
        guard let universalLink = qrCodeData.universalLink else { return }
        UIApplication.shared.open(universalLink)
    }
    
    // MARK: - Private Methods
    
    private func checkEntitlementAvailability() async {
        // In a real implementation, you would check if the entitlement is available
        // This is a simplified check for demonstration
        isEntitlementAvailable = true // Set to false if entitlement is not available
    }
    
    private func checkDeviceModelCompatibility() -> Bool {
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        
        // iPhone XR and later support eSIM
        // This is a simplified check - in production, you'd use more sophisticated device detection
        if systemName == "iPhone" {
            // You would implement proper device model checking here
            // For now, we'll assume all modern iPhones support eSIM
            return true
        }
        
        return false
    }
    
    private func validateRequest(_ request: ESIMProvisioningRequest) throws {
        guard !request.smdpAddress.isEmpty else {
            throw ESIMError.invalidRequest
        }
        
        guard !request.matchingID.isEmpty else {
            throw ESIMError.invalidRequest
        }
        
        // Add more validation as needed
    }
    
    private func performProvisioning(with request: CTCellularPlanProvisioningRequest) async -> ESIMProvisioningResult {
        return await withCheckedContinuation { continuation in
            cellularPlanProvisioning.addPlan(with: request) { result in
                let provisioningResult: ESIMProvisioningResult
                
                switch result {
                case .success:
                    provisioningResult = ESIMProvisioningResult(
                        isSuccess: true,
                        message: "eSIM profile installed successfully!"
                    )
                case .fail:
                    provisioningResult = ESIMProvisioningResult(
                        isSuccess: false,
                        message: "eSIM installation failed. Please check your details and try again.",
                        error: .provisioningFailed("CoreTelephony returned .fail")
                    )
                case .unknown:
                    provisioningResult = ESIMProvisioningResult(
                        isSuccess: false,
                        message: "Unknown error occurred during eSIM installation.",
                        error: .unknown("CoreTelephony returned .unknown")
                    )
                @unknown default:
                    provisioningResult = ESIMProvisioningResult(
                        isSuccess: false,
                        message: "Unexpected error occurred during eSIM installation.",
                        error: .unknown("CoreTelephony returned unknown result")
                    )
                }
                
                continuation.resume(returning: provisioningResult)
            }
        }
    }
}

// MARK: - Extensions

extension ESIMService {
    /// Resets the provisioning state
    public func resetProvisioningState() {
        provisioningState = ESIMProvisioningState()
    }
    
    /// Refreshes device compatibility status
    public func refreshCompatibility() async {
        await checkDeviceCompatibility()
    }
}
