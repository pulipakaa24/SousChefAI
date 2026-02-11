Note - this is an AI generated readme, and will be updated in the future.
# SousChefAI
A production-ready iOS app that uses multimodal AI to scan ingredients, generate personalized recipes, and provide real-time cooking guidance.

## Features

### 🎥 Intelligent Fridge Scanner
- Real-time ingredient detection using Overshoot API
- Camera-based scanning with live preview
- Confidence scoring for each detected ingredient
- Manual ingredient entry and editing

### 🍳 AI-Powered Recipe Generation
- Personalized recipe suggestions based on available ingredients
- Google Gemini AI for complex reasoning and recipe creation
- Filtering by "Scavenger" (use only what you have) or "Upgrader" (minimal shopping)
- Recipe scaling based on limiting ingredients
- Match scoring to prioritize best recipes

### 👨‍🍳 Live Cooking Mode
- Step-by-step guided cooking
- Real-time visual monitoring of cooking progress
- Text-to-speech announcements for hands-free cooking
- AI feedback when steps are complete
- Progress tracking and navigation

### 🔐 User Profiles & Persistence
- Firebase Firestore for cloud data sync
- Dietary restrictions (Vegan, Keto, Gluten-Free, etc.)
- Nutrition goals
- Saved recipes and pantry staples

## Architecture

The app follows **MVVM (Model-View-ViewModel)** with a **Repository Pattern** for clean separation of concerns:

```
├── Models/                 # Core data models (Codable, Identifiable)
│   ├── Ingredient.swift
│   ├── UserProfile.swift
│   └── Recipe.swift
│
├── Services/              # Business logic & external APIs
│   ├── VisionService.swift         # Protocol for vision AI
│   ├── OvershootVisionService.swift # Overshoot implementation
│   ├── RecipeService.swift         # Protocol for recipe generation
│   ├── GeminiRecipeService.swift   # Gemini implementation
│   ├── FirestoreRepository.swift   # Firebase data layer
│   └── CameraManager.swift         # AVFoundation camera handling
│
├── ViewModels/            # Business logic for views
│   ├── ScannerViewModel.swift
│   ├── RecipeGeneratorViewModel.swift
│   └── CookingModeViewModel.swift
│
├── Views/                 # SwiftUI views
│   ├── ScannerView.swift
│   ├── InventoryView.swift
│   ├── RecipeGeneratorView.swift
│   └── CookingModeView.swift
│
└── Config/                # App configuration
    └── AppConfig.swift
```

## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/souschef.git
cd souschef
```

### 2. Configure API Keys

Open `SousChefAI/Config/AppConfig.swift` and replace the placeholder values:

```swift
// Overshoot Vision API
static let overshootAPIKey = "YOUR_OVERSHOOT_API_KEY"

// Google Gemini API
static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
```

**Getting API Keys:**
- **Overshoot API**: Visit [overshoot.ai](https://overshoot.ai) (or the actual provider URL) and sign up
- **Gemini API**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey) and create an API key

### 3. Add Firebase

#### Add Firebase SDK via Swift Package Manager:
1. In Xcode: `File` > `Add Package Dependencies`
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: `10.0.0` or later
4. Add the following products:
   - `FirebaseAuth`
   - `FirebaseFirestore`

#### Add GoogleService-Info.plist:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add an iOS app with bundle ID: `com.yourcompany.SousChefAI`
4. Download `GoogleService-Info.plist`
5. Drag it into your Xcode project (ensure it's added to the SousChefAI target)

#### Enable Firebase in App:
1. Open `SousChefAI/SousChefAIApp.swift`
2. Uncomment the Firebase imports and initialization:
```swift
import FirebaseCore

init() {
    FirebaseApp.configure()
}
```

### 4. Add Google Generative AI SDK (Optional)

For better Gemini integration, add the official SDK:

```swift
// In Xcode: File > Add Package Dependencies
// URL: https://github.com/google/generative-ai-swift
```

Then update `GeminiRecipeService.swift` to use the SDK instead of REST API.

### 5. Configure Camera Permissions

The app requires camera access. Permissions are already handled in code, but ensure your `Info.plist` includes:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your fridge and monitor cooking progress</string>
```

### 6. Build and Run

1. Open `SousChefAI.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

## Usage Guide

### Scanning Your Fridge
1. Tap the **Scan** tab
2. Point your camera at your fridge or ingredients
3. Tap **Scan Fridge** to start detection
4. Review detected ingredients (yellow = low confidence)
5. Tap **Continue to Inventory**

### Managing Inventory
1. Edit quantities by tapping an ingredient
2. Swipe left to delete items
3. Add manual entries with the `+` button
4. Set dietary preferences before generating recipes
5. Tap **Generate Recipes** when ready

### Generating Recipes
1. Browse suggested recipes sorted by match score
2. Filter by:
   - **All Recipes**: Show everything
   - **The Scavenger**: Only use what you have
   - **The Upgrader**: Need 1-2 items max
   - **High Match**: 80%+ ingredient match
3. Tap a recipe to view details
4. Save favorites with the heart icon
5. Start cooking with **Start Cooking** button

### Cooking Mode
1. Enable **AI Monitoring** to watch your cooking
2. The AI will analyze your progress visually
3. Navigate steps with Previous/Next
4. Use **Read Aloud** for hands-free guidance
5. The AI will announce when steps are complete
6. View all steps with the list icon

## Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Architecture**: MVVM + Repository Pattern
- **Concurrency**: Swift Async/Await (no completion handlers)
- **Camera**: AVFoundation
- **Vision AI**: Overshoot API (real-time video inference)
- **Reasoning AI**: Google Gemini 2.0 Flash
- **Backend**: Firebase (Auth + Firestore)
- **Persistence**: Firebase Firestore (cloud sync)

## Protocol-Oriented Design

The app uses protocols for AI services to enable easy provider swapping:

```swift
protocol VisionService {
    func detectIngredients(from: AsyncStream<CVPixelBuffer>) async throws -> [Ingredient]
}

protocol RecipeService {
    func generateRecipes(inventory: [Ingredient], profile: UserProfile) async throws -> [Recipe]
}
```

To swap providers, simply create a new implementation:

```swift
final class OpenAIVisionService: VisionService {
    // Implementation using OpenAI Vision API
}

final class AnthropicRecipeService: RecipeService {
    // Implementation using Claude API
}
```

## Future Enhancements

- [ ] Nutrition tracking and calorie counting
- [ ] Shopping list generation
- [ ] Recipe sharing and social features
- [ ] Meal planning calendar
- [ ] Voice commands during cooking
- [ ] Multi-language support
- [ ] Apple Watch companion app
- [ ] Widget for quick recipe access
- [ ] Offline mode with local ML models
- [ ] Integration with smart kitchen appliances

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow Swift style guide and existing architecture
4. Write unit tests for new features
5. Update documentation as needed
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Overshoot AI for low-latency video inference
- Google Gemini for powerful reasoning capabilities
- Firebase for robust backend infrastructure
- Apple for SwiftUI and AVFoundation frameworks

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---
