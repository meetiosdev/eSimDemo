# iOS eSIM Implementation Guide

A comprehensive step-by-step guide for implementing eSIM functionality in iOS using Swift 5.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Apple Developer Account Setup](#apple-developer-account-setup)
3. [Project Configuration](#project-configuration)
4. [Info.plist Configuration](#infoplist-configuration)
5. [Entitlements Setup](#entitlements-setup)
6. [Swift Implementation](#swift-implementation)
7. [Testing](#testing)
8. [App Store Submission](#app-store-submission)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### Device Requirements
- **iOS Device**: iPhone XS or newer (eSIM support required)
- **iOS Version**: iOS 12.0 or later
- **Xcode**: Version 12.0 or later
- **Swift**: Version 5.0 or later

### Apple Developer Account
- **Paid Developer Account**: Required for eSIM entitlements
- **Organization Account**: Recommended for carrier partnerships

## Apple Developer Account Setup

### Step 1: Request eSIM Entitlement

1. **Contact Apple Developer Support**
   - Visit: [Apple Developer Support](https://developer.apple.com/support/)
   - Submit an entitlement request for eSIM functionality
   - Provide the following information:
     - **Issuer Name**: Your organization name
     - **Country Code**: Your country's mobile country code (MCC)
     - **App Name**: Your application name
     - **Team ID**: Your Apple Developer Team ID
     - **Adam ID**: Your App Store Connect App ID

2. **Wait for Approval**
   - Approval process can take 2-6 months
   - Apple will review your use case and business justification
   - You'll receive an email notification when approved

### Step 2: Configure App ID

1. **Log into Apple Developer Portal**
   - Go to [developer.apple.com](https://developer.apple.com)
   - Navigate to "Certificates, Identifiers & Profiles"

2. **Update App ID**
   - Select your App ID
   - Click "Edit"
   - Under "Additional Capabilities", enable:
     - ✅ **eSIM Development** (if available)
     - ✅ **Push Notifications** (recommended)
   - Click "Save"

### Step 3: Create Provisioning Profile

1. **Create New Provisioning Profile**
   - Go to "Profiles" section
   - Click "+" to create new profile
   - Select "iOS App Development" or "App Store"
   - Choose your App ID
   - Select your certificates
   - Select your devices (for development)
   - Name your profile (e.g., "MyApp eSIM Development")
   - Click "Generate"

2. **Download and Install**
   - Download the `.mobileprovision` file
   - Double-click to install in Xcode
   - Or drag to Xcode application

## Project Configuration

### Step 1: Xcode Project Setup

1. **Open Your Project in Xcode**
2. **Select Your Target**
3. **Go to "Signing & Capabilities"**
4. **Configure Signing**:
   - Uncheck "Automatically manage signing"
   - Select your Team
   - Choose the provisioning profile with eSIM entitlements

### Step 2: Add Required Frameworks

1. **Link CoreTelephony Framework**
   - Select your target
   - Go to "Build Phases"
   - Expand "Link Binary With Libraries"
   - Click "+" and add:
     - `CoreTelephony.framework`
     - `UIKit.framework`
     - `Foundation.framework`

## Info.plist Configuration

Add the following keys to your `Info.plist` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- eSIM Carrier Information -->
    <key>CarrierDescriptors</key>
    <array>
        <dict>
            <key>MCC</key>
            <string>YOUR_MCC_CODE</string>
            <key>MNC</key>
            <string>YOUR_MNC_CODE</string>
        </dict>
    </array>
    
    <!-- Network Security -->
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Communication Center Permissions -->
    <key>com.apple.CommCenter.fine-grained</key>
    <array>
        <string>spi</string>
        <string>sim-authentication</string>
        <string>identity</string>
    </array>
    
    <!-- WiFi Authentication -->
    <key>com.apple.wlan.authentication</key>
    <true/>
    
    <!-- Keychain Access Groups -->
    <key>keychain-access-groups</key>
    <array>
        <string>apple</string>
        <string>com.apple.identities</string>
        <string>com.apple.certificates</string>
    </array>
    
    <!-- Private System Keychain -->
    <key>com.apple.private.system-keychain</key>
    <true/>
    
    <!-- Privacy Usage Descriptions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to verify eSIM installation.</string>
    
    <key>NSLocalNetworkUsageDescription</key>
    <string>This app needs network access to download eSIM profiles.</string>
</dict>
</plist>
```

### Important Notes:
- Replace `YOUR_MCC_CODE` with your Mobile Country Code (e.g., "310" for US)
- Replace `YOUR_MNC_CODE` with your Mobile Network Code (e.g., "260" for T-Mobile US)
- These codes identify your carrier to Apple

## Entitlements Setup

### Step 1: Create Entitlements File

1. **Create New File**
   - File → New → File
   - Choose "Property List"
   - Name it `YourApp.entitlements`

2. **Add Entitlements**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.CommCenter.fine-grained</key>
    <array>
        <string>public-cellular-plan</string>
    </array>
    
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.yourapp</string>
    </array>
    
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.yourcompany.yourapp</string>
    </array>
</dict>
</plist>
```

### Step 2: Link Entitlements File

1. **Select Your Target**
2. **Go to "Build Settings"**
3. **Search for "Code Signing Entitlements"**
4. **Set the path to your entitlements file**

## Swift Implementation

### Step 1: Add ESIMManager to Your Project

1. **Copy the ESIMManager.swift file** to your Xcode project
2. **Add to Target**: Make sure it's included in your app target

### Step 2: Basic Implementation

```swift
import UIKit
import CoreTelephony

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupESIM()
    }
    
    private func setupESIM() {
        // Check if eSIM is supported
        if ESIMManager.shared.isESIMSupported() {
            print("eSIM is supported on this device")
        } else {
            print("eSIM is not supported on this device")
        }
    }
    
    @IBAction func installESIMButtonTapped(_ sender: UIButton) {
        // Example activation code (replace with actual QR code data)
        let activationCode = "LPA:1$smdp.example.com$MATCHING_ID"
        
        ESIMManager.shared.installESIM(activationCode: activationCode) { result in
            DispatchQueue.main.async {
                self.handleESIMResult(result)
            }
        }
    }
    
    private func handleESIMResult(_ result: ESIMInstallationResult) {
        switch result.status {
        case .success:
            showAlert(title: "Success", message: "eSIM installed successfully!")
        case .failure:
            showAlert(title: "Error", message: "eSIM installation failed: \(result.message ?? "Unknown error")")
        case .userCancelled:
            showAlert(title: "Cancelled", message: "User cancelled eSIM installation")
        case .notSupportedOrPermitted:
            showAlert(title: "Not Supported", message: "eSIM is not supported or permitted on this device")
        default:
            showAlert(title: "Error", message: "eSIM installation error: \(result.message ?? "Unknown error")")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Step 3: Advanced Implementation with Delegate Pattern

```swift
class ESIMViewController: UIViewController, ESIMManagerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ESIMManager.shared.delegate = self
    }
    
    // MARK: - ESIMManagerDelegate
    
    func esimManager(_ manager: ESIMManager, didCompleteInstallationWith result: ESIMInstallationResult) {
        DispatchQueue.main.async {
            self.showSuccessMessage("eSIM installed: \(result.message ?? "")")
        }
    }
    
    func esimManager(_ manager: ESIMManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            self.showErrorMessage("eSIM installation failed: \(error.localizedDescription)")
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        // Handle success
        print("Success: \(message)")
    }
    
    private func showErrorMessage(_ message: String) {
        // Handle error
        print("Error: \(message)")
    }
}
```

### Step 4: QR Code Integration

```swift
import AVFoundation

class QRCodeViewController: UIViewController {
    
    @IBAction func scanQRCodeButtonTapped(_ sender: UIButton) {
        // Present QR code scanner
        let scanner = QRCodeScannerViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }
}

extension QRCodeViewController: QRCodeScannerDelegate {
    func didScanQRCode(_ code: String) {
        // Validate and install eSIM
        if ESIMManager.shared.validateActivationCode(code) {
            ESIMManager.shared.installESIM(activationCode: code) { result in
                DispatchQueue.main.async {
                    self.handleESIMResult(result)
                }
            }
        } else {
            showAlert(title: "Invalid Code", message: "The scanned code is not a valid eSIM activation code")
        }
    }
}
```

## Testing

### Step 1: Device Testing

1. **Use Physical Device**
   - eSIM functionality cannot be tested in simulator
   - Use iPhone XS or newer with eSIM support

2. **Test Scenarios**
   - Valid activation code
   - Invalid activation code
   - Network connectivity issues
   - User cancellation
   - Multiple installation attempts

### Step 2: Debugging

```swift
// Enable detailed logging
class ESIMManager {
    private let isDebugMode = true
    
    private func log(_ message: String) {
        if isDebugMode {
            print("ESIMManager: \(message)")
        }
    }
}
```

### Step 3: Error Handling

```swift
// Comprehensive error handling
func handleESIMError(_ error: Error) {
    let nsError = error as NSError
    
    switch nsError.code {
    case -1009: // No internet
        showAlert(title: "No Internet", message: "Please check your internet connection")
    case -1001: // Timeout
        showAlert(title: "Timeout", message: "eSIM installation timed out. Please try again")
    default:
        showAlert(title: "Error", message: "eSIM installation failed: \(error.localizedDescription)")
    }
}
```

## App Store Submission

### Step 1: Prepare for Submission

1. **Test Thoroughly**
   - Test on multiple devices
   - Test various network conditions
   - Test user cancellation scenarios

2. **Prepare Documentation**
   - Create detailed app description
   - Explain eSIM functionality
   - Provide carrier partnership details

### Step 2: App Store Connect

1. **App Information**
   - **App Name**: Include "eSIM" in the name
   - **Description**: Clearly explain eSIM functionality
   - **Keywords**: Include "eSIM", "cellular", "mobile data"

2. **App Review Information**
   - **Notes**: Explain eSIM use case
   - **Contact Information**: Provide carrier contact details
   - **Demo Account**: If required for testing

### Step 3: Review Process

1. **Initial Review** (1-3 days)
   - Standard App Store review
   - Basic functionality testing

2. **eSIM Review** (Additional 1-2 weeks)
   - Apple's eSIM team review
   - Carrier verification
   - Entitlement validation

3. **Approval**
   - App goes live
   - Monitor for any issues

## Troubleshooting

### Common Issues

#### 1. "eSIM is not supported" Error
**Solution:**
- Verify device supports eSIM (iPhone XS+)
- Check iOS version (12.0+)
- Ensure proper entitlements

#### 2. "Not permitted" Error
**Solution:**
- Verify Apple has approved your eSIM entitlement
- Check provisioning profile includes eSIM capability
- Ensure manual code signing is configured

#### 3. Installation Fails Immediately
**Solution:**
- Check activation code format
- Verify network connectivity
- Check carrier server availability

#### 4. App Rejected by App Store
**Solution:**
- Provide detailed eSIM use case
- Include carrier partnership documentation
- Ensure compliance with App Store guidelines

### Debug Checklist

- [ ] Device supports eSIM
- [ ] iOS 12.0 or later
- [ ] Proper entitlements configured
- [ ] Valid provisioning profile
- [ ] Manual code signing enabled
- [ ] Info.plist properly configured
- [ ] Carrier descriptors added
- [ ] Network permissions granted

### Support Resources

1. **Apple Developer Documentation**
   - [CoreTelephony Framework](https://developer.apple.com/documentation/coretelephony)
   - [eSIM Guidelines](https://developer.apple.com/documentation/coretelephony/ctcellularplanprovisioning)

2. **Apple Developer Support**
   - Submit technical questions
   - Request additional entitlements
   - Report bugs

3. **Carrier Support**
   - Contact your carrier for activation codes
   - Verify SM-DP+ server availability
   - Test with carrier-provided test codes

## Conclusion

Implementing eSIM functionality in iOS requires careful planning, proper entitlements, and thorough testing. Follow this guide step-by-step to ensure a successful implementation. Remember that eSIM functionality is restricted and requires Apple's approval, so plan accordingly for the approval process.

For additional support or questions, refer to Apple's official documentation or contact Apple Developer Support.
