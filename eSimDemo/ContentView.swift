//
//  ContentView.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import SwiftUI

/// Main view of the eSIM Demo application
struct ContentView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = ESIMViewModel()
    @State private var showingQRCode = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Compatibility Status
                    ESIMCompatibilityView(
                        compatibilityStatus: viewModel.compatibilityStatus,
                        onRefresh: {
                            await viewModel.refreshCompatibility()
                        }
                    )
                    
                    // Provisioning Section
                    if viewModel.compatibilityStatus.isSupported {
                        ESIMProvisioningView(viewModel: viewModel)
                    }
                    
                    // Status Section
                    if viewModel.provisioningState.isProvisioning || viewModel.provisioningState.result != nil {
                        ESIMStatusView(
                            provisioningState: viewModel.provisioningState,
                            onReset: {
                                viewModel.resetProvisioning()
                            }
                        )
                    }
                    
                    // Entitlement Warning
                    if !viewModel.isEntitlementAvailable {
                        entitlementWarningView
                    }
                }
                .padding()
            }
            .navigationTitle("eSIM Demo")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingQRCode) {
                if let qrCodeData = viewModel.qrCodeData {
                    ESIMQRCodeView(
                        qrCodeData: qrCodeData,
                        onDismiss: {
                            showingQRCode = false
                            viewModel.dismissQRCode()
                        }
                    )
                }
            }
            .alert("Alert", isPresented: $viewModel.showAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .onChange(of: viewModel.showQRCode) { _, newValue in
                showingQRCode = newValue
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "simcard.2")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("eSIM Provisioning Demo")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Test eSIM installation and management")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var entitlementWarningView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Entitlement Required")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("This app requires the eSIM Cellular Plan entitlement from Apple to provision eSIM profiles directly. Without this entitlement, you can still generate QR codes for manual activation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
