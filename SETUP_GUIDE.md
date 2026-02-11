# SousChefAI - Quick Setup Guide

This guide will help you get SousChefAI up and running.

## Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Active internet connection for API calls

## Step 1: Configure API Keys

### Overshoot Vision API

1. Visit the Overshoot API provider website and create an account
2. Generate an API key for video inference
3. Open `SousChefAI/Config/AppConfig.swift`
4. Replace `INSERT_KEY_HERE` with your Overshoot API key:

```swift
static let overshootAPIKey = "your_overshoot_api_key_here"
```

### Google Gemini API

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. In `SousChefAI/Config/AppConfig.swift`, replace:

```swift
static let geminiAPIKey = "your_gemini_api_key_here"
```

## Step 2: Add Firebase (Optional but Recommended)

### Add Firebase SDK

1. In Xcode, go to `File` > `Add Package Dependencies`
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version `10.0.0` or later
4. Add these products to your target:
   - FirebaseAuth
   - FirebaseFirestore

### Configure Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Click "Add app" and select iOS
4. Enter bundle identifier: `com.yourcompany.SousChefAI`
5. Download `GoogleService-Info.plist`
6. Drag the file into your Xcode project (ensure it's added to the SousChefAI target)

### Enable Firebase in Code

1. Open `SousChefAI/SousChefAIApp.swift`
2. Uncomment these lines:

```swift
import FirebaseCore

init() {
    FirebaseApp.configure()
}
```

### Configure Firestore Database

1. In Firebase Console, go to Firestore Database
2. Click "Create database"
3. Start in test mode (or production mode with proper rules)
4. Choose a location close to your users

## Step 3: Configure Camera Permissions (CRITICAL)

⚠️ **The app will crash without this step!**

### Add Privacy Descriptions in Xcode

1. In Xcode, select the **SousChefAI** target
2. Go to the **Info** tab
3. Under "Custom iOS Target Properties", click the **+** button
4. Add these two keys:

**Camera Permission:**
- **Key**: `Privacy - Camera Usage Description` (or `NSCameraUsageDescription`)
- **Value**: `SousChefAI needs camera access to scan your fridge for ingredients and monitor your cooking progress in real-time.`

**Microphone Permission:**
- **Key**: `Privacy - Microphone Usage Description` (or `NSMicrophoneUsageDescription`)
- **Value**: `SousChefAI uses the microphone to provide voice-guided cooking instructions.`

📖 See [PRIVACY_SETUP.md](PRIVACY_SETUP.md) for detailed step-by-step instructions with screenshots.

## Step 4: Build and Run

1. Open `SousChefAI.xcodeproj` in Xcode
2. Select your target device (iOS 17.0+ required)
3. Press `⌘ + R` to build and run
4. Allow camera permissions when prompted

## Testing Without API Keys

If you want to test the UI without API keys:

1. The app will show placeholder data and errors for API calls
2. You can still navigate through the UI
3. Manual ingredient entry will work
4. Recipe generation will fail gracefully

## Troubleshooting

### Build Errors

**"Missing GoogleService-Info.plist"**
- Ensure the file is in your project and added to the target
- Check that it's not in a subdirectory

**"Module 'Firebase' not found"**
- Make sure you added the Firebase package correctly
- Clean build folder: `⌘ + Shift + K`
- Rebuild: `⌘ + B`

**"API Key Missing" errors**
- Check that you replaced "INSERT_KEY_HERE" in AppConfig.swift
- API keys should be strings without quotes inside the quotes

### Runtime Errors

**"Camera access denied"**
- Go to Settings > Privacy & Security > Camera
- Enable camera access for SousChefAI

**"Network request failed"**
- Check internet connection
- Verify API keys are valid
- Check API endpoint URLs in AppConfig.swift

**"Firebase configuration error"**
- Ensure GoogleService-Info.plist is properly added
- Verify Firebase initialization is uncommented
- Check Firestore is enabled in Firebase Console

## Architecture Overview

The app follows MVVM architecture with clean separation:

```
Views → ViewModels → Services → APIs/Firebase
  ↓         ↓           ↓
Models ← Repository ← Firestore
```

## Next Steps

Once the app is running:

1. **Test the Scanner**: Point camera at ingredients and scan
2. **Review Inventory**: Edit quantities and add items manually
3. **Set Preferences**: Configure dietary restrictions
4. **Generate Recipes**: Get AI-powered recipe suggestions
5. **Cooking Mode**: Try the live cooking assistant

## Optional Enhancements

### Add Google Generative AI SDK

For better Gemini integration:

1. Add package: `https://github.com/google/generative-ai-swift`
2. Update `GeminiRecipeService.swift` to use the SDK
3. Uncomment the SDK-based code in the service

### Configure Overshoot WebSocket

If using WebSocket for real-time detection:

1. Update `overshootWebSocketURL` in AppConfig.swift
2. Verify the WebSocket endpoint with Overshoot documentation
3. Test real-time detection in Scanner view

## Support

For issues or questions:
- Check the main [README.md](README.md)
- Open an issue on GitHub
- Review the inline documentation in code files

## Security Notes

⚠️ **Important**: Never commit API keys to version control!

Consider:
- Using environment variables for keys
- Adding `AppConfig.swift` to `.gitignore` (but keep a template)
- Using a secrets management service in production
- Rotating keys regularly

---

**You're all set! Happy cooking with SousChefAI! 🍳**
