import Foundation
import Combine

class SetupManager: ObservableObject {
    @Published var statusText: String = "Ready to install."
    @Published var isInstalling: Bool = false
    @Published var progress: Double = 0.0
    @Published var hasError: Bool = false
    
    let appSupportURL: URL
    let binDirURL: URL
    let cliExecutableURL: URL
    
    init() {
        let baseAppSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = baseAppSupport.appendingPathComponent("com.tanoomohal.Blink")
        binDirURL = appSupportURL.appendingPathComponent("bin")
        cliExecutableURL = binDirURL.appendingPathComponent("arduino-cli")
    }
    
    func beginSetup(completion: @escaping () -> Void) {
        isInstalling = true
        hasError = false
        statusText = "Preparing directories..."
        progress = 0.1
        
        do {
            try FileManager.default.createDirectory(at: binDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.statusText = "Failed to create directory: \(error.localizedDescription)"
                self.isInstalling = false
            }
            return
        }
        
        statusText = "Downloading Arduino CLI..."
        progress = 0.3
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.downloadAndInstallCLI { success in
                guard success else { return }
                
                DispatchQueue.main.async {
                    self.statusText = "Configuring Arduino CLI..."
                    self.progress = 0.7
                }
                
                self.configureCLI { configSuccess in
                    DispatchQueue.main.async {
                        if configSuccess {
                            self.statusText = "Setup Complete!"
                            self.progress = 1.0
                            self.isInstalling = false
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    private func downloadAndInstallCLI(completion: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let script = "curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=\"\(binDirURL.path)\" sh"
        process.arguments = ["-c", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.statusText = output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            pipe.fileHandleForReading.readabilityHandler = nil
            
            if process.terminationStatus == 0 {
                completion(true)
            } else {
                DispatchQueue.main.async {
                    self.hasError = true
                    self.statusText = "Installation failed with status \(process.terminationStatus)."
                    self.isInstalling = false
                }
                completion(false)
            }
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.statusText = "Download failed: \(error.localizedDescription)"
                self.isInstalling = false
            }
            completion(false)
        }
    }
    
    private func configureCLI(completion: @escaping (Bool) -> Void) {
        // Run: arduino-cli config init
        let configProcess = Process()
        configProcess.executableURL = cliExecutableURL
        configProcess.arguments = ["config", "init", "--overwrite"]
        
        do {
            try configProcess.run()
            configProcess.waitUntilExit()
            
            DispatchQueue.main.async {
                self.statusText = "Updating core indices..."
                self.progress = 0.85
            }
            
            // Run: arduino-cli core update-index
            let updateProcess = Process()
            updateProcess.executableURL = cliExecutableURL
            updateProcess.arguments = ["core", "update-index"]
            try updateProcess.run()
            updateProcess.waitUntilExit()
            
            completion(updateProcess.terminationStatus == 0)
        } catch {
            DispatchQueue.main.async {
                self.hasError = true
                self.statusText = "Configuration failed: \(error.localizedDescription)"
                self.isInstalling = false
            }
            completion(false)
        }
    }
}
