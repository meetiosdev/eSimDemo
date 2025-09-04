//
//  ESIMStatusView.swift
//  eSimDemo
//
//  Created by Swarajmeet Singh on 04/09/25.
//

import SwiftUI

/// View displaying eSIM provisioning status and progress
struct ESIMStatusView: View {
    
    // MARK: - Properties
    
    let provisioningState: ESIMProvisioningState
    let onReset: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Provisioning Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Status Card
            VStack(spacing: 16) {
                // Status Icon and Text
                VStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 48))
                        .foregroundColor(statusColor)
                    
                    Text(provisioningState.currentStep.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
                
                // Progress Bar
                if provisioningState.isProvisioning {
                    VStack(spacing: 8) {
                        ProgressView(value: provisioningState.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text("\(Int(provisioningState.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Result Message
                if let result = provisioningState.result {
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.isSuccess ? .green : .red)
                            
                            Text(result.message)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        
                        // Error Details
                        if let error = result.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Reset Button
                if provisioningState.result != nil {
                    Button(action: onReset) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if provisioningState.isProvisioning {
            return "arrow.clockwise"
        } else if let result = provisioningState.result {
            return result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if provisioningState.isProvisioning {
            return .blue
        } else if let result = provisioningState.result {
            return result.isSuccess ? .green : .red
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview("Provisioning") {
    let state = ESIMProvisioningState()
    state.isProvisioning = true
    state.currentStep = .provisioning
    state.progress = 0.6
    
    return ESIMStatusView(provisioningState: state) {
        // Preview reset action
    }
    .padding()
}

#Preview("Success") {
    let state = ESIMProvisioningState()
    state.isProvisioning = false
    state.currentStep = .completed
    state.progress = 1.0
    state.result = ESIMProvisioningResult(
        isSuccess: true,
        message: "eSIM profile installed successfully!"
    )
    
    return ESIMStatusView(provisioningState: state) {
        // Preview reset action
    }
    .padding()
}

#Preview("Failed") {
    let state = ESIMProvisioningState()
    state.isProvisioning = false
    state.currentStep = .failed
    state.progress = 0.0
    state.result = ESIMProvisioningResult(
        isSuccess: false,
        message: "eSIM installation failed",
        error: .provisioningFailed("Invalid credentials")
    )
    
    return ESIMStatusView(provisioningState: state) {
        // Preview reset action
    }
    .padding()
}
