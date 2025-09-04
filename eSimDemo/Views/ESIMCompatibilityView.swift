//
//  ESIMCompatibilityView.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import SwiftUI

/// View displaying device eSIM compatibility status
struct ESIMCompatibilityView: View {
    
    // MARK: - Properties
    
    let compatibilityStatus: ESIMCompatibilityStatus
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "simcard.2")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("eSIM Compatibility")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: refreshCompatibility) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .disabled(isRefreshing)
            }
            
            // Status Card
            VStack(spacing: 12) {
                // Status Icon
                Image(systemName: compatibilityStatus.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(compatibilityStatus.isSupported ? .green : .red)
                
                // Status Text
                Text(compatibilityStatus.isSupported ? "eSIM Supported" : "eSIM Not Supported")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(compatibilityStatus.isSupported ? .green : .red)
                
                // Device Information
                VStack(spacing: 8) {
                    HStack {
                        Text("Device:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(compatibilityStatus.deviceModel)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("iOS Version:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(compatibilityStatus.iosVersion)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.subheadline)
                
                // Reason (if not supported)
                if let reason = compatibilityStatus.reason {
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Reason:")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            
            // Refresh Indicator
            if isRefreshing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking compatibility...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func refreshCompatibility() {
        Task {
            isRefreshing = true
            await onRefresh()
            isRefreshing = false
        }
    }
}

// MARK: - Preview

#Preview("Supported Device") {
    ESIMCompatibilityView(
        compatibilityStatus: ESIMCompatibilityStatus(
            isSupported: true,
            deviceModel: "iPhone 15 Pro",
            iosVersion: "18.1"
        )
    ) {
        // Preview refresh action
    }
    .padding()
}

#Preview("Unsupported Device") {
    ESIMCompatibilityView(
        compatibilityStatus: ESIMCompatibilityStatus(
            isSupported: false,
            deviceModel: "iPhone 8",
            iosVersion: "16.0",
            reason: "Device model does not support eSIM"
        )
    ) {
        // Preview refresh action
    }
    .padding()
}
