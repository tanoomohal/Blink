import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup: Bool = false
    @StateObject private var setupManager = SetupManager()
    @State private var currentTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch currentTab {
                case 0:
                    // Slide 1: Welcome
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        Text("Welcome to Blink")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("A modern, lightweight IDE for Arduino. Built entirely in SwiftUI, designed for speed and simplicity.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                case 1:
                    // Slide 2: Dynamic Interface
                    VStack(spacing: 20) {
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 80))
                            .foregroundColor(.cyan)
                        Text("Beautiful & Native")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Experience the new Liquid Glass design language. Crisp, translucent toolbars that look fantastic on macOS.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                case 2:
                    // Slide 3: All-In-One Tools
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        Text("Everything You Need")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Built-in Library Manager, Board Auto-Discovery, Core installation, and an integrated Serial Monitor.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity)
                case 3:
                    // Slide 4: Setup
                    VStack(spacing: 20) {
                        Image(systemName: "cpu")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        Text("Let's Get Started")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Blink uses the official `arduino-cli` under the hood. We'll automatically download and configure it for you so you never have to open the terminal.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                        
                        if setupManager.isInstalling {
                            VStack {
                                ProgressView(value: setupManager.progress)
                                    .progressViewStyle(.linear)
                                    .frame(width: 300)
                                Text(setupManager.statusText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .frame(width: 300)
                            }
                            .padding(.top, 20)
                        } else {
                            Button(action: {
                                setupManager.beginSetup {
                                    hasCompletedSetup = true
                                }
                            }) {
                                Text(setupManager.hasError ? "Retry Setup" : "Install Requirements & Start")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 20)
                            
                            if setupManager.hasError {
                                Text(setupManager.statusText)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 300)
                            }
                        }
                    }
                    .transition(.opacity)
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
            
            // Navigation Dots Workaround / Next Button
            HStack {
                if currentTab > 0 {
                    Button("Back") {
                        withAnimation { currentTab -= 1 }
                    }
                }
                Spacer()
                if currentTab < 3 {
                    Button("Next") {
                        withAnimation { currentTab += 1 }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
