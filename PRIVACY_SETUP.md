# Privacy Configuration for SousChefAI

## Camera Permission Setup (Required)

The app needs camera access to scan ingredients and monitor cooking. Follow these steps to add the required privacy descriptions:

### Method 1: Using Xcode Target Settings (Recommended)

1. Open the project in Xcode
2. Select the **SousChefAI** target in the project navigator
3. Go to the **Info** tab
4. Under "Custom iOS Target Properties", click the **+** button
5. Add the following keys with their values:

**Camera Permission:**
- **Key**: `Privacy - Camera Usage Description`
- **Value**: `SousChefAI needs camera access to scan your fridge for ingredients and monitor your cooking progress in real-time.`

**Microphone Permission (for voice guidance):**
- **Key**: `Privacy - Microphone Usage Description`
- **Value**: `SousChefAI uses the microphone to provide voice-guided cooking instructions.`

### Method 2: Manual Info.plist (Alternative)

If you prefer to manually edit the Info.plist:

1. In Xcode, right-click on the SousChefAI folder
2. Select **New File** → **Property List**
3. Name it `Info.plist`
4. Add these entries:

```xml
<key>NSCameraUsageDescription</key>
<string>SousChefAI needs camera access to scan your fridge for ingredients and monitor your cooking progress in real-time.</string>

<key>NSMicrophoneUsageDescription</key>
<string>SousChefAI uses the microphone to provide voice-guided cooking instructions.</string>
```

## Verifying the Setup

After adding the privacy descriptions:

1. Clean the build folder: **Product → Clean Build Folder** (⌘ + Shift + K)
2. Rebuild the project: **Product → Build** (⌘ + B)
3. Run on a device or simulator
4. When you first open the Scanner view, you should see a permission dialog

## Troubleshooting

### "App crashed when accessing camera"
- Ensure you added `NSCameraUsageDescription` to the target's Info settings
- Clean and rebuild the project
- Restart Xcode if the permission isn't taking effect

### "Permission dialog not appearing"
- Check that the Info settings were saved
- Try deleting the app from the simulator/device and reinstalling
- Reset privacy settings on the simulator: **Device → Erase All Content and Settings**

### "Multiple Info.plist errors"
- Modern Xcode projects use automatic Info.plist generation
- Use Method 1 (Target Settings) instead of creating a manual file
- If you created Info.plist manually, make sure to configure the build settings to use it

## Privacy Manifest

The `PrivacyInfo.xcprivacy` file is included for App Store compliance. This declares:
- No tracking
- No third-party SDK tracking domains
- Camera access is for app functionality only

## Testing Camera Permissions

1. Build and run the app
2. Navigate to the **Scan** tab
3. You should see a permission dialog
4. Grant camera access
5. The camera preview should appear

If permission is denied:
- Go to **Settings → Privacy & Security → Camera**
- Find **SousChefAI** and enable it
- Relaunch the app

---

**Note**: These privacy descriptions are required by Apple's App Store guidelines. Apps that access camera without proper usage descriptions will be rejected.
