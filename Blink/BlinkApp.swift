//
//  BlinkApp.swift
//  Blink
//
//  Created by Tanoo Mohal on 6/25/26.
//

import SwiftUI

@main
struct BlinkApp: App {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedSetup {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}
