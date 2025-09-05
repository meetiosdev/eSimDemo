# Core Telephony Framework - Complete Learning Guide

## Overview

The Core Telephony framework provides access to cellular service information and eSIM management capabilities on iOS devices. This guide covers all aspects of the framework based on Apple's official documentation and practical implementation examples.

## Table of Contents
1. [Framework Introduction](#framework-introduction)
2. [Key Classes and Protocols](#key-classes-and-protocols)
3. [eSIM Management](#esim-management)
4. [Service Information](#service-information)
5. [Subscriber Information](#subscriber-information)
6. [Cellular Data Access](#cellular-data-access)
7. [Error Handling](#error-handling)
8. [Practical Implementation](#practical-implementation)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Framework Introduction

### Purpose
- Access information about user's cellular service provider
- Manage eSIM profiles and cellular plans
- Monitor cellular data access permissions
- Handle subscriber information and authentication

### Platform Support
- **iOS**: 4.0+
- **iPadOS**: 4.0+
- **Mac Catalyst**: 14.0+
- **macOS**: 10.10+

### Important Notes
- VoIP and cellular services are unavailable in visionOS
- eSIM functionality requires iOS 12.0+ and special entitlements
- Some features require paid Apple Developer account

## Key Classes and Protocols

### 1. CTTelephonyNetworkInfo
**Purpose**: Provides notifications of changes to cellular service provider

```swift
import CoreTelephony

class NetworkInfoManager {
    private let networkInfo = CTTelephonyNetworkInfo()
    
    func setupNetworkMonitoring() {
        // Monitor carrier changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carrierDidUpdate),
            name: .CTCarrierDidUpdate,
            object: nil
        )
    }
    
    @objc private func carrierDidUpdate() {
        // Handle carrier changes
        print("Carrier information updated")
    }
}
```

### 2. CTCarrier (Deprecated but still useful for reference)
**Purpose**: Information about cellular service provider

```swift
// Note: CTCarrier is deprecated, use CTTelephonyNetworkInfo instead
func getCarrierInfo() {
    let networkInfo = CTTelephonyNetworkInfo()
    
    if let carrier = networkInfo.subscriberCellularProvider {
        print("Carrier Name: \(carrier.carrierName ?? "Unknown")")
        print("Mobile Country Code: \(carrier.mobileCountryCode ?? "Unknown")")
        print("Mobile Network Code: \(carrier.mobileNetworkCode ?? "Unknown")")
        print("Allows VoIP: \(carrier.allowsVOIP)")
    }
}
```

## eSIM Management

### Core Classes

#### 1. CTCellularPlanProvisioning
**Purpose**: Download and install carrier eSIM profiles

```swift
import CoreTelephony

class ESIMProvisioningManager {
    private let planProvisioning = CTCellularPlanProvisioning()
    
    func installESIM(activationCode: String, completion: @escaping (Bool, Error?) -> Void) {
        let request = CTCellularPlanProvisioningRequest()
        request.address = activationCode
        
        planProvisioning.addPlan(with: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true, nil)
                case .fail:
                    completion(false, NSError(domain: "ESIMError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Installation failed"]))
                case .cancel:
                    completion(false, NSError(domain: "ESIMError", code: -2, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
                case .unknown:
                    completion(false, NSError(domain: "ESIMError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                @unknown default:
                    completion(false, NSError(domain: "ESIMError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unexpected error"]))
                }
            }
        }
    }
    
    func checkESIMSupport() -> Bool {
        return planProvisioning.supportsCellularPlan()
    }
}
```

#### 2. CTCellularPlanProvisioningRequest
**Purpose**: Request specifying an eSIM to download and install

```swift
func createProvisioningRequest(activationCode: String, confirmationCode: String? = nil) -> CTCellularPlanProvisioningRequest {
    let request = CTCellularPlanProvisioningRequest()
    request.address = activationCode
    
    if let confirmationCode = confirmationCode {
        request.confirmationCode = confirmationCode
    }
    
    return request
}
```

#### 3. CTCellularPlanProperties
**Purpose**: Properties for an eSIM

```swift
// Note: This class is used internally by the system
// You typically don't create instances directly
```

#### 4. CTCellularPlanCapability (Beta)
**Purpose**: Type of cellular plan available for an eSIM

```swift
// Available capabilities (iOS 16.0+)
enum PlanCapability {
    case data
    case voice
    case dataAndVoice
}
```

### SIM Authentication

#### CTCellularPlanStatus
**Purpose**: Retrieve and check validity of a token

```swift
func checkSIMStatus() {
    // This is typically used for SIM authentication
    // Implementation depends on specific carrier requirements
}
```

## Service Information

### CTTelephonyNetworkInfo Usage

```swift
class CellularServiceManager {
    private let networkInfo = CTTelephonyNetworkInfo()
    
    func getCurrentCarrierInfo() {
        // Get current carrier information
        if let carrier = networkInfo.subscriberCellularProvider {
            print("Current Carrier: \(carrier.carrierName ?? "Unknown")")
            print("MCC: \(carrier.mobileCountryCode ?? "Unknown")")
            print("MNC: \(carrier.mobileNetworkCode ?? "Unknown")")
            print("ISO Country Code: \(carrier.isoCountryCode ?? "Unknown")")
            print("Allows VoIP: \(carrier.allowsVOIP)")
        }
        
        // Get service subscriber cellular providers (iOS 12.0+)
        if let serviceProviders = networkInfo.serviceSubscriberCellularProviders {
            for (key, carrier) in serviceProviders {
                print("Service \(key): \(carrier.carrierName ?? "Unknown")")
            }
        }
    }
    
    func monitorCarrierChanges() {
        // Set up carrier change monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carrierDidUpdate),
            name: .CTCarrierDidUpdate,
            object: nil
        )
    }
    
    @objc private func carrierDidUpdate() {
        print("Carrier information has been updated")
        getCurrentCarrierInfo()
    }
}
```

## Subscriber Information

### CTSubscriber
**Purpose**: Cellular network subscriber information

```swift
class SubscriberManager: NSObject {
    private let subscriber = CTSubscriber()
    
    override init() {
        super.init()
        subscriber.delegate = self
    }
}

extension SubscriberManager: CTSubscriberDelegate {
    func subscriberTokenRefreshed(_ subscriber: CTSubscriber) {
        print("Subscriber token refreshed")
        // Handle token refresh
    }
}
```

### CTSubscriberInfo
**Purpose**: Array of cellular network subscribers

```swift
func getSubscriberInfo() {
    let subscriberInfo = CTSubscriberInfo()
    // Access subscriber information
    // Note: Specific implementation depends on carrier requirements
}
```

## Cellular Data Access

### CTCellularData
**Purpose**: Check if app can access cellular data

```swift
class CellularDataManager {
    private let cellularData = CTCellularData()
    
    func checkCellularDataAccess() {
        switch cellularData.restrictedState {
        case .notRestricted:
            print("Cellular data access is not restricted")
        case .restricted:
            print("Cellular data access is restricted")
        case .restrictedStateUnknown:
            print("Cellular data access state is unknown")
        @unknown default:
            print("Unknown cellular data access state")
        }
    }
}
```

## Error Handling

### CTError
**Purpose**: Core Telephony specific errors

```swift
func handleCoreTelephonyError(_ error: Error) {
    if let ctError = error as? CTError {
        switch ctError.code {
        case .noError:
            print("No error")
        case .invalidParameter:
            print("Invalid parameter provided")
        case .noConnection:
            print("No connection available")
        case .invalidRequest:
            print("Invalid request")
        case .denied:
            print("Request denied")
        case .unsupported:
            print("Operation not supported")
        case .unknown:
            print("Unknown error")
        @unknown default:
            print("Unexpected error code")
        }
    }
}
```

## Practical Implementation

### Complete eSIM Manager Implementation

```swift
import Foundation
import CoreTelephony
import UIKit

public class AdvancedESIMManager: NSObject {
    
    // MARK: - Singleton
    public static let shared = AdvancedESIMManager()
    
    // MARK: - Properties
    private let planProvisioning = CTCellularPlanProvisioning()
    private let networkInfo = CTTelephonyNetworkInfo()
    private let cellularData = CTCellularData()
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Check if device supports eSIM
    public func isESIMSupported() -> Bool {
        guard #available(iOS 12.0, *) else { return false }
        return planProvisioning.supportsCellularPlan()
    }
    
    /// Get current carrier information
    public func getCurrentCarrierInfo() -> [String: Any] {
        var carrierInfo: [String: Any] = [:]
        
        if let carrier = networkInfo.subscriberCellularProvider {
            carrierInfo["carrierName"] = carrier.carrierName
            carrierInfo["mobileCountryCode"] = carrier.mobileCountryCode
            carrierInfo["mobileNetworkCode"] = carrier.mobileNetworkCode
            carrierInfo["isoCountryCode"] = carrier.isoCountryCode
            carrierInfo["allowsVOIP"] = carrier.allowsVOIP
        }
        
        return carrierInfo
    }
    
    /// Check cellular data access
    public func getCellularDataStatus() -> String {
        switch cellularData.restrictedState {
        case .notRestricted:
            return "Not Restricted"
        case .restricted:
            return "Restricted"
        case .restrictedStateUnknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Install eSIM with comprehensive error handling
    public func installESIM(
        activationCode: String,
        confirmationCode: String? = nil,
        completion: @escaping (Result<Bool, ESIMError>) -> Void
    ) {
        // Validate inputs
        guard !activationCode.isEmpty else {
            completion(.failure(.invalidActivationCode))
            return
        }
        
        guard isESIMSupported() else {
            completion(.failure(.notSupported))
            return
        }
        
        // Create request
        let request = CTCellularPlanProvisioningRequest()
        request.address = activationCode
        if let confirmationCode = confirmationCode {
            request.confirmationCode = confirmationCode
        }
        
        // Start installation
        planProvisioning.addPlan(with: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(true))
                case .fail:
                    completion(.failure(.installationFailed))
                case .cancel:
                    completion(.failure(.userCancelled))
                case .unknown:
                    completion(.failure(.unknownError))
                @unknown default:
                    completion(.failure(.unknownError))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carrierDidUpdate),
            name: .CTCarrierDidUpdate,
            object: nil
        )
    }
    
    @objc private func carrierDidUpdate() {
        print("Carrier information updated")
        // Handle carrier changes
    }
}

// MARK: - Error Types
public enum ESIMError: Error, LocalizedError {
    case invalidActivationCode
    case notSupported
    case installationFailed
    case userCancelled
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .invalidActivationCode:
            return "Invalid activation code provided"
        case .notSupported:
            return "eSIM is not supported on this device"
        case .installationFailed:
            return "eSIM installation failed"
        case .userCancelled:
            return "User cancelled eSIM installation"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}
```

## Best Practices

### 1. Error Handling
```swift
// Always handle all possible error cases
func installESIMSafely(activationCode: String) {
    ESIMManager.shared.installESIM(activationCode: activationCode) { result in
        switch result {
        case .success:
            // Handle success
            break
        case .failure(let error):
            // Handle specific error types
            switch error {
            case .invalidActivationCode:
                // Show user-friendly message
                break
            case .notSupported:
                // Guide user to supported device
                break
            default:
                // Handle other errors
                break
            }
        }
    }
}
```

### 2. User Experience
```swift
// Provide clear feedback to users
func showESIMStatus() {
    if ESIMManager.shared.isESIMSupported() {
        showMessage("eSIM is supported on this device")
    } else {
        showMessage("eSIM is not supported. Requires iPhone XS or newer with iOS 12.0+")
    }
}
```

### 3. Network Monitoring
```swift
// Monitor carrier changes for dynamic updates
class CarrierMonitor {
    private let networkInfo = CTTelephonyNetworkInfo()
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(carrierChanged),
            name: .CTCarrierDidUpdate,
            object: nil
        )
    }
    
    @objc private func carrierChanged() {
        // Update UI or perform necessary actions
        updateCarrierInformation()
    }
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. eSIM Not Supported
**Symptoms**: `isESIMSupported()` returns false
**Solutions**:
- Check device compatibility (iPhone XS or newer)
- Verify iOS version (12.0 or later)
- Ensure proper entitlements are configured

#### 2. Installation Fails
**Symptoms**: Installation always fails
**Solutions**:
- Validate activation code format
- Check network connectivity
- Verify carrier server availability
- Ensure proper entitlements

#### 3. App Store Rejection
**Symptoms**: App rejected due to eSIM functionality
**Solutions**:
- Provide detailed use case documentation
- Include carrier partnership information
- Ensure compliance with App Store guidelines
- Request proper entitlements from Apple

### Debug Checklist
- [ ] Device supports eSIM (iPhone XS+)
- [ ] iOS 12.0 or later
- [ ] Proper entitlements configured
- [ ] Valid provisioning profile
- [ ] Manual code signing enabled
- [ ] Info.plist properly configured
- [ ] Network permissions granted
- [ ] Activation code format validated

## Deprecated Classes (For Reference)

### CTCall (Deprecated)
**Note**: Use CallKit instead for call management

### CTCallCenter (Deprecated)
**Note**: Use CallKit instead for call center functionality

## Conclusion

The Core Telephony framework provides powerful capabilities for cellular service management and eSIM provisioning. Key points to remember:

1. **eSIM functionality requires special entitlements** from Apple
2. **Device compatibility** is essential (iPhone XS+ with iOS 12.0+)
3. **Proper error handling** is crucial for good user experience
4. **Network monitoring** helps keep information up-to-date
5. **App Store approval** may take additional time for eSIM apps

This framework is essential for carrier apps and eSIM management applications, but requires careful planning and Apple's approval for full functionality.
