//
//  ESIMProvisioningView.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import SwiftUI

/// View for eSIM provisioning input and controls
struct ESIMProvisioningView: View {
    
    // MARK: - Properties
    
    @Bindable var viewModel: ESIMViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("eSIM Provisioning")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Input Form
            VStack(spacing: 16) {
                // SM-DP+ Address
                VStack(alignment: .leading, spacing: 8) {
                    Text("SM-DP+ Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., rsp.truphone.com", text: $viewModel.smdpAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.smdpAddress) { _, _ in
                            viewModel.updateInputValidation()
                        }
                    
                    // Validation feedback
                    if !viewModel.smdpAddress.isEmpty && !ESIMUtilities.validateSMDPAddress(viewModel.smdpAddress) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Invalid SM-DP+ address format")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // Matching ID
                VStack(alignment: .leading, spacing: 8) {
                    Text("Matching ID (Activation Code)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., JQ-209U6H-6I82J5", text: $viewModel.matchingID)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.matchingID) { _, _ in
                            viewModel.updateInputValidation()
                        }
                    
                    // Validation feedback
                    if !viewModel.matchingID.isEmpty && !ESIMUtilities.validateMatchingID(viewModel.matchingID) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("Invalid Matching ID format (minimum 8 characters)")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // Optional Fields Section
                DisclosureGroup("Optional Fields") {
                    VStack(spacing: 16) {
                        // Confirmation Code
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirmation Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Optional confirmation code", text: $viewModel.confirmationCode)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // EID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EID (eUICC Identifier)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Optional EID", text: $viewModel.eid)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: viewModel.eid) { _, _ in
                                    viewModel.updateInputValidation()
                                }
                            
                            // Validation feedback
                            if !viewModel.eid.isEmpty && !ESIMUtilities.validateEID(viewModel.eid) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Invalid EID format (32 hexadecimal characters)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                        
                        // ICCID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ICCID")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Optional ICCID", text: $viewModel.iccid)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: viewModel.iccid) { _, _ in
                                    viewModel.updateInputValidation()
                                }
                            
                            // Validation feedback
                            if !viewModel.iccid.isEmpty && !ESIMUtilities.validateICCID(viewModel.iccid) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Invalid ICCID format (19-20 digits)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            // Action Buttons
            VStack(spacing: 12) {
                // Provision eSIM Button
                Button(action: provisionESIM) {
                    HStack {
                        if viewModel.provisioningState.isProvisioning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "simcard.2")
                        }
                        
                        Text(viewModel.provisioningState.isProvisioning ? "Installing..." : "Install eSIM Profile")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(canProvisionESIM ? Color.blue : Color.gray)
                    )
                    .foregroundColor(.white)
                }
                .disabled(!canProvisionESIM || viewModel.provisioningState.isProvisioning)
                
                // Alternative Actions
                HStack(spacing: 12) {
                    // Generate QR Code Button
                    Button(action: viewModel.generateQRCode) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Generate QR Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                    }
                    .disabled(!viewModel.isInputValid)
                    
                    // Open Settings Button
                    Button(action: viewModel.openSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .foregroundColor(.gray)
                    }
                }
                
                // Universal Link Button (iOS 17.4+)
                if #available(iOS 17.4, *) {
                    Button(action: viewModel.openUniversalLink) {
                        HStack {
                            Image(systemName: "link")
                            Text("Open Universal Link")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green, lineWidth: 1)
                        )
                        .foregroundColor(.green)
                    }
                    .disabled(!viewModel.isInputValid)
                }
            }
            
            // Sample Data Button
            Button(action: viewModel.loadSampleData) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Load Sample Data")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProvisionESIM: Bool {
        viewModel.canProvisionESIM
    }
    
    // MARK: - Private Methods
    
    private func provisionESIM() {
        Task {
            await viewModel.provisionESIM()
        }
    }
}

// MARK: - Preview

#Preview {
    ESIMProvisioningView(viewModel: ESIMViewModel())
        .padding()
}
