# SousChefAI - Quick Start Checklist ✅

Get up and running in 5 minutes!

## Prerequisites Check

- [ ] macOS 14.0+ with Xcode 15.0+
- [ ] iOS 17.0+ device or simulator
- [ ] Internet connection

## Step-by-Step Setup

### 1️⃣ Configure Privacy (CRITICAL - App will crash without this!)

**In Xcode:**
1. Select the **SousChefAI** target
2. Go to **Info** tab
3. Click **+** under "Custom iOS Target Properties"
4. Add:
   - Key: `Privacy - Camera Usage Description`
   - Value: `SousChefAI needs camera access to scan your fridge for ingredients and monitor your cooking progress in real-time.`
5. Click **+** again and add:
   - Key: `Privacy - Microphone Usage Description`  
   - Value: `SousChefAI uses the microphone to provide voice-guided cooking instructions.`

✅ **Status**: [ ] Privacy descriptions added

### 2️⃣ Add API Keys

**File**: `SousChefAI/Config/AppConfig.swift`

Replace:
```swift
static let overshootAPIKey = "INSERT_KEY_HERE"
static let geminiAPIKey = "INSERT_KEY_HERE"
```

With your actual API keys from:
- **Overshoot**: [Your Overshoot Provider]
- **Gemini**: https://makersuite.google.com/app/apikey

✅ **Status**: 
- [ ] Overshoot API key added
- [ ] Gemini API key added

### 3️⃣ Add Firebase (Optional - for cloud sync)

**Add Package:**
1. File → Add Package Dependencies
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Add products: `FirebaseAuth`, `FirebaseFirestore`

**Configure:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Drag into Xcode (ensure it's added to target)
3. Uncomment in `SousChefAIApp.swift`:
```swift
import FirebaseCore

init() {
    FirebaseApp.configure()
}
```

✅ **Status**: 
- [ ] Firebase package added
- [ ] GoogleService-Info.plist added
- [ ] Firebase initialized

### 4️⃣ Build & Run

1. Open `SousChefAI.xcodeproj`
2. Select target device (iOS 17.0+)
3. Press **⌘ + R**
4. Grant camera permission when prompted

✅ **Status**: [ ] App running successfully

## Minimum Viable Setup (Test Mode)

Want to just see the UI without external services?

**Required:**
- ✅ Privacy descriptions (Step 1)

**Optional:**
- ⚠️ API keys (will show errors but UI works)
- ⚠️ Firebase (uses local data only)

## Verification

After setup, test these features:

- [ ] Scanner tab opens camera
- [ ] Can add manual ingredients
- [ ] Inventory view displays items
- [ ] Profile tab shows configuration status
- [ ] No crash when opening camera

## Common Issues

### ❌ App crashes immediately when opening Scanner
→ **Fix**: Add camera privacy description (Step 1)

### ❌ "API Key Missing" errors
→ **Fix**: Replace "INSERT_KEY_HERE" in AppConfig.swift (Step 2)

### ❌ "Module 'Firebase' not found"
→ **Fix**: Add Firebase package via SPM (Step 3)

### ❌ Camera permission dialog doesn't appear
→ **Fix**: Delete app, clean build (⌘+Shift+K), rebuild, reinstall

## Next Steps

Once running:

1. **Scan Mode**: Point camera at ingredients → tap "Scan Fridge"
2. **Inventory**: Review detected items → edit quantities → set preferences
3. **Generate Recipes**: Tap "Generate Recipes" → browse suggestions
4. **Cook**: Select recipe → "Start Cooking" → enable AI monitoring

## Documentation

- **Full Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- **Privacy**: [PRIVACY_SETUP.md](PRIVACY_SETUP.md)
- **Architecture**: [README.md](README.md)

## Support

Issues? Check:
1. Privacy descriptions are added ✓
2. API keys are valid strings (not "INSERT_KEY_HERE") ✓
3. Target is iOS 17.0+ ✓
4. Clean build folder and rebuild ✓

---

**Ready to cook with AI! 🍳**
