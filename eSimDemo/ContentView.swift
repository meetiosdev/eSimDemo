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
    @State private var qrCodeImage: UIImage?
    @State private var showQRCode = false
    
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
                            
                            // eSIM Support Debug Info
                            DetailSection(title: "eSIM Support Debug") {
                                let supportInfo = ESIMManager.shared.getESIMSupportInfo()
                                DetailRow(label: "API Supported", value: (supportInfo["apiSupported"] as? Bool) == true ? "Yes" : "No")
                                DetailRow(label: "Device Capable", value: (supportInfo["deviceCapable"] as? Bool) == true ? "Yes" : "No")
                                DetailRow(label: "Overall Supported", value: (supportInfo["overallSupported"] as? Bool) == true ? "Yes" : "No")
                                DetailRow(label: "Entitlements", value: supportInfo["entitlementsStatus"] as? String ?? "Unknown")
                                DetailRow(label: "iOS Version", value: supportInfo["iosVersion"] as? String ?? "Unknown")
                                DetailRow(label: "Device Model", value: supportInfo["deviceModel"] as? String ?? "Unknown")
                            }
                            
                            // QR Code Section
                            DetailSection(title: "QR Code") {
                                VStack(spacing: 12) {
                                    if let qrImage = qrCodeImage {
                                        Image(uiImage: qrImage)
                                            .interpolation(.none)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 200, height: 200)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .shadow(radius: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 200, height: 200)
                                            .overlay(
                                                VStack {
                                                    Image(systemName: "qrcode")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.gray)
                                                    Text("QR Code")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            )
                                    }
                                    
                                    HStack(spacing: 16) {
                                        Button(action: generateQRCode) {
                                            HStack {
                                                Image(systemName: "qrcode")
                                                Text(qrCodeImage == nil ? "Generate QR Code" : "Regenerate QR Code")
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        if qrCodeImage != nil {
                                            Button(action: shareQRCode) {
                                                HStack {
                                                    Image(systemName: "square.and.arrow.up")
                                                    Text("Share")
                                                }
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                            }
                                        }
                                    }
                                    
                                    if let lpaComponents = parseActivationCode(esimResponse.response.eSim.activationCode) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("LPA Components:")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            if let smdp = lpaComponents.smdp {
                                                Text("SMDP: \(smdp)")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            if let token = lpaComponents.token {
                                                Text("Token: \(token)")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
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
            .onChange(of: jsonLoader.esimResponse) { _ in
                // Auto-generate QR code when eSIM data is loaded
                if jsonLoader.esimResponse != nil {
                    generateQRCode()
                }
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
    
    // MARK: - QR Code Generation
    private func generateQRCode() {
        guard let esimResponse = jsonLoader.esimResponse else { return }
        
        let activationCode = esimResponse.response.eSim.activationCode
        print("ContentView: Generating QR code for activation code: \(activationCode)")
        
        if let qrImage = ESIMManager.shared.generateESIMQRCode(activationCode: activationCode, scale: 8) {
            qrCodeImage = qrImage
            print("ContentView: QR code generated successfully")
        } else {
            print("ContentView: Failed to generate QR code")
        }
    }
    
    // MARK: - LPA Parsing
    private func parseActivationCode(_ activationCode: String) -> LPAComponents? {
        let lpaComponents = ESIMManager.shared.parseLPA(activationCode)
        return lpaComponents.isValid ? lpaComponents : nil
    }
    
    // MARK: - QR Code Sharing
    private func shareQRCode() {
        guard let qrImage = qrCodeImage,
              let esimResponse = jsonLoader.esimResponse else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [
                qrImage,
                "eSIM Activation Code: \(esimResponse.response.eSim.activationCode)"
            ],
            applicationActivities: nil
        )
        
        // For iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            activityViewController.popoverPresentationController?.sourceView = window
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
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
