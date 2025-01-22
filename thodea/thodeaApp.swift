//
//  thodeaApp.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/22/24.
//

import SwiftUI
import FirebaseCore

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        let cacheSize = 500 * 1024 * 1024 // 500MB
        URLCache.shared.memoryCapacity = cacheSize
        URLCache.shared.diskCapacity = cacheSize

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Iterate over all connected scenes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = windowScene.windows.first {
                    window.backgroundColor = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)
                }
            }
        }
        //FirebaseApp.configure()

        return true
    }
}

@main
struct thodeaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
