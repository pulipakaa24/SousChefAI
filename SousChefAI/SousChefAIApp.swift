//
//  SousChefAIApp.swift
//  SousChefAI
//
//  Created by Aditya Pulipaka on 2/11/26.
//

import SwiftUI
// Uncomment when Firebase package is added
// import FirebaseCore

@main
struct SousChefAIApp: App {
    
    // Uncomment when Firebase package is added
    // init() {
    //     FirebaseApp.configure()
    // }
    
    // [INSERT_FIREBASE_GOOGLESERVICE-INFO.PLIST_SETUP_HERE]
    // Firebase Setup Instructions:
    // 1. Add Firebase to your project via Swift Package Manager
    //    - File > Add Package Dependencies
    //    - URL: https://github.com/firebase/firebase-ios-sdk
    //    - Add: FirebaseAuth, FirebaseFirestore
    // 2. Download GoogleService-Info.plist from Firebase Console
    // 3. Add it to the Xcode project (drag into project navigator)
    // 4. Ensure it's added to the SousChefAI target
    // 5. Uncomment the FirebaseCore import and init() above
    
    @StateObject private var repository = FirestoreRepository()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repository)
        }
    }
}
