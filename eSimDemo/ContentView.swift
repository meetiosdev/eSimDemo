//
//  ContentView.swift
//  EsimDemo
//
//  Created by Swarajmeet Singh on 05/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var jsonLoader = JSONLoader()
    @State private var isInstalling = false
    @State private var installationResult: ESIMInstallationResult?
    @State private var showInstallationAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if jsonLoader.isLoading {
                    ProgressView("Loading eSIM data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = jsonLoader.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            jsonLoader.loadESIMData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let esimResponse = jsonLoader.esimResponse {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("eSIM Profile Details")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Circle()
                                        .fill(esimResponse.response.eSim.state == "ERROR" ? Color.red : Color.green)
                                        .frame(width: 12, height: 12)
                                    Text(esimResponse.response.eSim.state)
                                        .font(.headline)
                                        .foregroundColor(esimResponse.response.eSim.state == "ERROR" ? .red : .green)
                                }
                            }
                            .padding(.bottom)
                            
                            // Basic Information
                            DetailSection(title: "Basic Information") {
                                DetailRow(label: "ICCID", value: esimResponse.response.eSim.iccid)
                                DetailRow(label: "IMSI", value: String(esimResponse.response.eSim.imsi))
                                DetailRow(label: "EID", value: esimResponse.response.eSim.eid)
                                DetailRow(label: "Activation Code", value: esimResponse.response.eSim.activationCode)
                            }
                            
                            // Status Information
                            DetailSection(title: "Status") {
                                DetailRow(label: "State Message", value: esimResponse.response.eSim.stateMessage)
                                DetailRow(label: "Last Operation", value: esimResponse.response.eSim.lastOperationDate.toHumanReadableDate)
                                DetailRow(label: "Release Date", value: esimResponse.response.eSim.releaseDate.toHumanReadableDate)
                            }
                            
                            // Configuration
                            DetailSection(title: "Configuration") {
                                DetailRow(label: "Reuse Enabled", value: esimResponse.response.eSim.reuseEnabled ? "Yes" : "No")
                                DetailRow(label: "CC Required", value: esimResponse.response.eSim.ccRequired ? "Yes" : "No")
                                DetailRow(label: "Reuse Remaining", value: String(esimResponse.response.eSim.reuseRemainingCount))
                            }
                            
                            // Reuse Policy
                            DetailSection(title: "Reuse Policy") {
                                DetailRow(label: "Reuse Type", value: esimResponse.response.eSim.profileReusePolicy.reuseType)
                                DetailRow(label: "Max Count", value: esimResponse.response.eSim.profileReusePolicy.maxCount)
                            }
                        }
                        .padding()
                        
                        // eSIM Install Button
                        VStack(spacing: 12) {
                            Divider()
                                .padding(.horizontal)
                            
                            Button(action: installESIM) {
                                HStack {
                                    if isInstalling {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "simcard.fill")
                                    }
                                    Text(isInstalling ? "Installing eSIM..." : "Install eSIM")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(esimResponse.response.eSim.state == "ERROR" ? Color.red : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isInstalling || esimResponse.response.eSim.activationCode.isEmpty)
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "simcard")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("eSIM Demo")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Tap the button below to load eSIM data")
                            .foregroundColor(.secondary)
                        Button("Load eSIM Data") {
                            jsonLoader.loadESIMData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("eSIM Demo")
            .onAppear {
                // Auto-load data when view appears
                jsonLoader.loadESIMData()
            }
            .alert("eSIM Installation", isPresented: $showInstallationAlert) {
                Button("OK") {
                    installationResult = nil
                }
            } message: {
                if let result = installationResult {
                    Text(installationMessage(for: result))
                }
            }
        }
    }
    
    // MARK: - eSIM Installation
    private func installESIM() {
        guard let esimResponse = jsonLoader.esimResponse else { return }
        
        isInstalling = true
        installationResult = nil
        
        ESIMManager.shared.installESIM(activationCode: esimResponse.response.eSim.activationCode) { result in
            DispatchQueue.main.async {
                self.isInstalling = false
                self.installationResult = result
                self.showInstallationAlert = true
            }
        }
    }
    
    private func installationMessage(for result: ESIMInstallationResult) -> String {
        switch result.status {
        case .success:
            return "✅ eSIM installed successfully!\n\n\(result.message ?? "Installation completed.")"
        case .failure:
            return "❌ Installation failed!\n\n\(result.message ?? "Unknown error occurred.")"
        case .userCancelled:
            return "⚠️ Installation cancelled by user.\n\n\(result.message ?? "User cancelled the installation.")"
        case .notSupportedOrPermitted:
            return "❌ eSIM not supported!\n\n\(result.message ?? "eSIM functionality is not available on this device.")"
        case .invalidActivationCode:
            return "❌ Invalid activation code!\n\n\(result.message ?? "The provided activation code is invalid.")"
        case .esimDisabledOrUnavailable:
            return "❌ eSIM unavailable!\n\n\(result.message ?? "eSIM is disabled or unavailable.")"
        case .networkError:
            return "❌ Network error!\n\n\(result.message ?? "Please check your internet connection.")"
        case .storageFull:
            return "❌ Storage full!\n\n\(result.message ?? "Device storage is full.")"
        case .timeout:
            return "❌ Installation timeout!\n\n\(result.message ?? "Installation took too long to complete.")"
        case .unknownError:
            return "❌ Unknown error!\n\n\(result.message ?? "An unexpected error occurred.")"
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 4) {
                content
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}

//com.apple.developer.coretelephony.sim-inserted
