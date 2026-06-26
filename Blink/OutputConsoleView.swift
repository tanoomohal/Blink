import SwiftUI

struct OutputConsoleView: View {
    @Binding var selectedTab: Int // 0 for Console, 1 for Serial Monitor
    @Binding var consoleOutput: String
    
    @ObservedObject var serialMonitor: SerialMonitorConnection
    @Binding var serialInput: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                Text("OUTPUT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Theme.panelBackground)
            
            Divider()
                .background(Theme.border)
            
            // Tab Bar
            HStack(spacing: 12) {
                OutputTab(title: "Console", isActive: selectedTab == 0) {
                    selectedTab = 0
                }
                OutputTab(title: "Serial Monitor", isActive: selectedTab == 1) {
                    selectedTab = 1
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Theme.background)
            
            Divider()
                .background(Theme.border)
            
            // Content
            ZStack(alignment: .bottom) {
                if selectedTab == 0 {
                    ScrollView {
                        Text(consoleOutput)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(Color(Theme.plainText))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Theme.background)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            Text(serialMonitor.output)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(Color(Theme.plainText))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .background(Theme.background)
                        
                        Divider().background(Theme.border)
                        
                        HStack {
                            TextField("Send message...", text: $serialInput)
                                .textFieldStyle(.plain)
                                .foregroundColor(Color(Theme.plainText))
                                .onSubmit {
                                    if !serialInput.isEmpty {
                                        serialMonitor.send(text: serialInput)
                                        serialInput = ""
                                    }
                                }
                            
                            Button("Send") {
                                if !serialInput.isEmpty {
                                    serialMonitor.send(text: serialInput)
                                    serialInput = ""
                                }
                            }
                            .disabled(!serialMonitor.isRunning)
                        }
                        .padding()
                        .background(Theme.panelBackground)
                    }
                }
                
                // Floating Control Bar
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    Button(action: {}) {
                        Image(systemName: "textformat")
                    }
                    Button(action: {}) {
                        Image(systemName: "pencil")
                    }
                    Button(action: {}) {
                        Image(systemName: "message")
                    }
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.panelBackground)
                        .overlay(
                            Capsule().stroke(Theme.border, lineWidth: 1)
                        )
                )
                .padding(.bottom, 16)
            }
        }
    }
}

struct OutputTab: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isActive ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isActive ? Theme.accent : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
