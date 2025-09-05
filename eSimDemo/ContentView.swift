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
                    loadingView
                } else if let errorMessage = jsonLoader.errorMessage {
                    errorView(errorMessage)
                } else if let esimResponse = jsonLoader.esimResponse {
                    esimContentView(esimResponse)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("eSIM Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        jsonLoader.loadESIMData()
                    }
                }
            }
            .onAppear {
                jsonLoader.loadESIMData()
            }
            .onChange(of: jsonLoader.esimResponse) {
                if jsonLoader.esimResponse != nil {
                    generateQRCode()
                }
            }
            .alert("Installation Result", isPresented: $showInstallationAlert) {
                Button("OK") { }
            } message: {
                if let result = installationResult {
                    Text("Status: \(result.status.rawValue)\nMessage: \(result.message ?? "No message")")
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        ProgressView("Loading eSIM data...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ errorMessage: String) -> some View {
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
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "simcard")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("No eSIM Data")
                .font(.title2)
                .fontWeight(.bold)
            Text("Tap 'Load Data' to load eSIM profile information")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Load Data") {
                jsonLoader.loadESIMData()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func esimContentView(_ esimResponse: ESIMResponse) -> some View {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                headerView(esimResponse)
                supportStatusView()
                qrCodeSection()
                lpaParsingSection(esimResponse)
                profileDetailsSection(esimResponse)
                installButtonSection()
            }
            .padding()
        }
    }
    
    private func headerView(_ esimResponse: ESIMResponse) -> some View {
                            VStack(alignment: .leading, spacing: 8) {
            Text("eSIM Profile")
                .font(.largeTitle)
                                    .fontWeight(.bold)
                                
            Text("Activation Code: \(esimResponse.response.eSim.activationCode)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
        .padding(.bottom, 8)
    }
    
    private func supportStatusView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
                                HStack {
                Image(systemName: ESIMManager.shared.isESIMSupported() ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(ESIMManager.shared.isESIMSupported() ? .green : .red)
                Text("eSIM Support")
                                        .font(.headline)
                Spacer()
                Text(ESIMManager.shared.isESIMSupported() ? "Supported" : "Not Supported")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !ESIMManager.shared.isESIMSupported() {
                Text("This device may not support eSIM or requires additional entitlements.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func qrCodeSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QR Code")
                    .font(.headline)
                Spacer()
                Button(action: generateQRCode) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text(qrCodeImage == nil ? "Generate QR Code" : "Regenerate QR Code")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if let qrImage = qrCodeImage {
                VStack(spacing: 12) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    
                    HStack(spacing: 16) {
                        Button(action: generateQRCode) {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Regenerate")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
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
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Tap 'Generate QR Code' to create a QR code for this eSIM profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private func lpaParsingSection(_ esimResponse: ESIMResponse) -> some View {
        Group {
            if let lpaComponents = parseActivationCode(esimResponse.response.eSim.activationCode) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("LPA Components")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lpaComponents.displayString)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
        }
    }
    
    private func profileDetailsSection(_ esimResponse: ESIMResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Details")
                .font(.headline)
            
            // Basic Info
            DetailSection(title: "Basic Information") {
                DetailRow(label: "Activation Code", value: esimResponse.response.eSim.activationCode)
                DetailRow(label: "ICCID", value: esimResponse.response.eSim.iccid)
                DetailRow(label: "IMSI", value: String(esimResponse.response.eSim.imsi))
                DetailRow(label: "State", value: esimResponse.response.eSim.state)
            }
                            
                            // Reuse Policy
                            DetailSection(title: "Reuse Policy") {
                                DetailRow(label: "Reuse Type", value: esimResponse.response.eSim.profileReusePolicy.reuseType)
                                DetailRow(label: "Max Count", value: esimResponse.response.eSim.profileReusePolicy.maxCount)
                            }
            
            // eSIM Support Debug Info
            DetailSection(title: "eSIM Support Debug") {
                let supportInfo = ESIMManager.shared.getESIMSupportInfo()
                DetailRow(label: "API Supported", value: supportInfo.apiSupported ? "Yes" : "No")
                DetailRow(label: "Device Capable", value: supportInfo.deviceCapable ? "Yes" : "No")
                DetailRow(label: "Overall Supported", value: supportInfo.overallSupported ? "Yes" : "No")
                DetailRow(label: "Entitlements", value: supportInfo.entitlementsStatus)
                DetailRow(label: "iOS Version", value: supportInfo.iosVersion)
                DetailRow(label: "Device Model", value: supportInfo.deviceModel)
                DetailRow(label: "Entitlements Issue", value: supportInfo.entitlementsIssue ? "Yes" : "No")
            }
                        }
                        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
                        
    private func installButtonSection() -> some View {
                        VStack(spacing: 12) {
                            Button(action: installESIM) {
                                HStack {
                                    if isInstalling {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                        Image(systemName: "plus.circle.fill")
                                    }
                    Text(isInstalling ? "Installing eSIM..." : "Install eSIM Profile")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                .background(ESIMManager.shared.isESIMSupported() ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
            }
            .disabled(isInstalling || !ESIMManager.shared.isESIMSupported())
            
            if !ESIMManager.shared.isESIMSupported() {
                Text("eSIM installation is not supported on this device")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
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
        
        if let qrImage = ESIMManager.shared.generateESIMQRCode(
            activationCode: esimResponse.response.eSim.activationCode,
            scale: 10
        ) {
            qrCodeImage = qrImage
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
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Detail Components

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
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
                content
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    ContentView()
}