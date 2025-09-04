//
//  ESIMViewModel.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import Foundation
import SwiftUI

/// ViewModel responsible for managing eSIM UI state and business logic
@Observable
public final class ESIMViewModel {
    
    // MARK: - Published Properties
    
    public var smdpAddress: String = ""
    public var matchingID: String = ""
    public var confirmationCode: String = ""
    public var eid: String = ""
    public var iccid: String = ""
    
    public var isInputValid: Bool = false
    public var showQRCode: Bool = false
    public var showAlert: Bool = false
    public var alertMessage: String = ""
    
    // MARK: - Private Properties
    
    private let esimService: ESIMService
    
    // MARK: - Computed Properties
    
    public var compatibilityStatus: ESIMCompatibilityStatus {
        esimService.compatibilityStatus
    }
    
    public var provisioningState: ESIMProvisioningState {
        esimService.provisioningState
    }
    
    public var isEntitlementAvailable: Bool {
        esimService.isEntitlementAvailable
    }
    
    public var canProvisionESIM: Bool {
        compatibilityStatus.isSupported && isEntitlementAvailable && isInputValid
    }
    
    public var qrCodeData: ESIMQRCodeData? {
        guard isInputValid else { return nil }
        return esimService.generateQRCodeData(from: currentRequest)
    }
    
    // MARK: - Initialization
    
    public init(esimService: ESIMService = ESIMService()) {
        self.esimService = esimService
        setupInputValidation()
    }
    
    // MARK: - Public Methods
    
    /// Provisions eSIM with current input values
    public func provisionESIM() async {
        let request = currentRequest
        await esimService.provisionESIM(with: request)
    }
    
    /// Generates QR code for eSIM activation
    public func generateQRCode() {
        guard isInputValid else {
            showAlert(message: "Please fill in all required fields")
            return
        }
        showQRCode = true
    }
    
    /// Opens eSIM settings
    public func openSettings() {
        esimService.openESIMSettings()
    }
    
    /// Opens eSIM Universal Link (iOS 17.4+)
    @available(iOS 17.4, *)
    public func openUniversalLink() {
        guard let qrCodeData = qrCodeData else {
            showAlert(message: "Please fill in all required fields")
            return
        }
        esimService.openESIMUniversalLink(with: qrCodeData)
    }
    
    /// Refreshes device compatibility
    public func refreshCompatibility() async {
        await esimService.refreshCompatibility()
    }
    
    /// Resets the provisioning state
    public func resetProvisioning() {
        esimService.resetProvisioningState()
    }
    
    /// Clears all input fields
    public func clearInputs() {
        smdpAddress = ""
        matchingID = ""
        confirmationCode = ""
        eid = ""
        iccid = ""
    }
    
    /// Shows an alert with the given message
    public func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    /// Dismisses the QR code view
    public func dismissQRCode() {
        showQRCode = false
    }
    
    // MARK: - Private Methods
    
    private func setupInputValidation() {
        // This would typically use Combine or other reactive programming
        // For simplicity, we'll validate on each input change
        validateInputs()
    }
    
    private func validateInputs() {
        isInputValid = !smdpAddress.isEmpty && !matchingID.isEmpty
    }
    
    private var currentRequest: ESIMProvisioningRequest {
        ESIMProvisioningRequest(
            smdpAddress: smdpAddress,
            matchingID: matchingID,
            confirmationCode: confirmationCode.isEmpty ? nil : confirmationCode,
            eid: eid.isEmpty ? nil : eid,
            iccid: iccid.isEmpty ? nil : iccid
        )
    }
}

// MARK: - Input Validation

extension ESIMViewModel {
    /// Updates input validation when fields change
    public func updateInputValidation() {
        validateInputs()
    }
}

// MARK: - Sample Data

extension ESIMViewModel {
    /// Loads sample data for testing
    public func loadSampleData() {
        smdpAddress = "rsp.truphone.com"
        matchingID = "JQ-209U6H-6I82J5"
        confirmationCode = ""
        eid = ""
        iccid = ""
        updateInputValidation()
    }
}
