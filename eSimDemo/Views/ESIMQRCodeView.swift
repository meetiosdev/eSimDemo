//
//  ESIMQRCodeView.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// View displaying QR code for eSIM activation
struct ESIMQRCodeView: View {
    
    // MARK: - Properties
    
    let qrCodeData: ESIMQRCodeData
    let onDismiss: () -> Void
    
    @State private var qrCodeImage: UIImage?
    @State private var showingShareSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("eSIM QR Code")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Scan this QR code to install your eSIM profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // QR Code
                VStack(spacing: 16) {
                    if let qrCodeImage = qrCodeImage {
                        Image(uiImage: qrCodeImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 200)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.2)
                            )
                    }
                }
                
                // QR Code Data
                VStack(spacing: 12) {
                    Text("QR Code Data:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(qrCodeData.qrCodeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .textSelection(.enabled)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Share Button
                    Button(action: shareQRCode) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share QR Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    
                    // Universal Link Button (iOS 17.4+)
                    if #available(iOS 17.4, *), let universalLink = qrCodeData.universalLink {
                        Button(action: openUniversalLink) {
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
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("eSIM QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .onAppear {
                generateQRCode()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrCodeImage = qrCodeImage {
                    ShareSheet(activityItems: [qrCodeImage])
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(qrCodeData.qrCodeString.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaleX = 200 / outputImage.extent.size.width
            let scaleY = 200 / outputImage.extent.size.height
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    private func shareQRCode() {
        showingShareSheet = true
    }
    
    @available(iOS 17.4, *)
    private func openUniversalLink() {
        if let universalLink = qrCodeData.universalLink {
            UIApplication.shared.open(universalLink)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ESIMQRCodeView(
        qrCodeData: ESIMQRCodeData(
            smdpAddress: "rsp.truphone.com",
            matchingID: "JQ-209U6H-6I82J5"
        )
    ) {
        // Preview dismiss action
    }
}
