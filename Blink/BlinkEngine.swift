import Foundation
import Combine

// --- JSON Response Models ---

struct LibrarySearchResponse: Codable {
    let libraries: [LibraryResult]?
}

struct LibraryResult: Codable, Identifiable {
    var id: String { name }
    let name: String
    let sentence: String?
}

// Board List Models
struct BoardListResponse: Codable {
    let detected_ports: [DetectedPort]?
}

struct DetectedPort: Codable {
    let port: PortDetail
}

struct PortDetail: Codable {
    let address: String
}

// Board List All Models
struct BoardListAllResponse: Codable {
    let boards: [BoardDetail]?
}

struct BoardDetail: Codable {
    let name: String
    let fqbn: String
}

// Core Search Models
struct CoreSearchResponse: Codable {
    let platforms: [CoreResult]?
}

struct CoreResult: Codable, Identifiable {
    var id: String
    let maintainer: String?
    let website: String?
    let installed_version: String?
    let latest_version: String?
}

// Library Examples Models
struct LibExamplesResponse: Codable {
    let examples: [ExampleResult]?
}

struct ExampleResult: Codable, Identifiable {
    var id: String { library.name + (library.examples.first ?? "") }
    let library: ExampleLibraryDetail
}

struct ExampleLibraryDetail: Codable {
    let name: String
    let examples: [String]
}

// This class handles the communication with the terminal
class ArduinoCLI: ObservableObject {
    // @Published updates the UI automatically when text is added
    @Published var consoleOutput: String = ""
    
    // Path to the arduino-cli executable. We prioritize our bundled setup.
    var cliPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundledCLI = appSupport.appendingPathComponent("com.tanoomohal.Blink/bin/arduino-cli")
        if FileManager.default.fileExists(atPath: bundledCLI.path) {
            return bundledCLI.path
        }
        return "/opt/homebrew/bin/arduino-cli" // Fallback
    }

    // A simple test function to list connected devices
    func listBoards() {
        runCommand(arguments: ["board", "list"])
    }
    
    // Compiles the sketch (equivalent to the "Verify" checkmark in Arduino IDE)
    func compileSketch(fqbn: String, sketchPath: String) {
        runCommand(arguments: ["compile", "--fqbn", fqbn, sketchPath])
    }

    // Flashes the code to the microcontroller (equivalent to the "Upload" arrow)
    func uploadSketch(fqbn: String, port: String, sketchPath: String) {
        runCommand(arguments: ["upload", "-p", port, "--fqbn", fqbn, sketchPath])
    }

    // --- Library Search Methods ---
    
    // Executes a JSON-formatted search to parse directly into the UI
    func searchLibrariesJSON(query: String) async -> [LibraryResult] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["lib", "search", query, "--format", "json"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            // Parse JSON from the CLI
            let decoder = JSONDecoder()
            let response = try decoder.decode(LibrarySearchResponse.self, from: data)
            return response.libraries ?? []
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "Failed to parse search results. Error: \(error.localizedDescription)\n"
            }
            return []
        }
    }

    // --- Dynamic Port & Board Discovery ---
    func fetchPortsAndBoards() async -> (ports: [String], boards: [String]) {
        var foundPorts: [String] = []
        var foundBoards: [String] = []
        
        // Fetch ports
        let portProcess = Process()
        portProcess.executableURL = URL(fileURLWithPath: cliPath)
        portProcess.arguments = ["board", "list", "--format", "json"]
        let portPipe = Pipe()
        portProcess.standardOutput = portPipe
        
        do {
            try portProcess.run()
            let data = portPipe.fileHandleForReading.readDataToEndOfFile()
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(BoardListResponse.self, from: data), let detected = response.detected_ports {
                foundPorts = detected.map { $0.port.address }
            }
        } catch {}
        
        // Fetch all boards
        let boardProcess = Process()
        boardProcess.executableURL = URL(fileURLWithPath: cliPath)
        boardProcess.arguments = ["board", "listall", "--format", "json"]
        let boardPipe = Pipe()
        boardProcess.standardOutput = boardPipe
        
        do {
            try boardProcess.run()
            let data = boardPipe.fileHandleForReading.readDataToEndOfFile()
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(BoardListAllResponse.self, from: data), let b = response.boards {
                foundBoards = b.map { $0.fqbn }
            }
        } catch {}
        
        return (foundPorts, foundBoards)
    }
    
    // --- Core Management ---
    func searchCoresJSON(query: String) async -> [CoreResult] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["core", "search", query, "--format", "json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let decoder = JSONDecoder()
            let response = try decoder.decode(CoreSearchResponse.self, from: data)
            return response.platforms ?? []
        } catch {
            return []
        }
    }
    
    func installCore(id: String) {
        runCommand(arguments: ["core", "install", id])
    }

    // --- Sketch Examples ---
    func getExamplesJSON() async -> [ExampleResult] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = ["lib", "examples", "--format", "json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let decoder = JSONDecoder()
            let response = try decoder.decode(LibExamplesResponse.self, from: data)
            return response.examples ?? []
        } catch {
            return []
        }
    }
    
    // --- File Management Methods ---
    
    // Creates a new Arduino sketch folder and .ino file with standard boilerplate code
    func createNewSketch(name: String, saveDirectory: URL) -> URL? {
        let sketchFolderURL = saveDirectory.appendingPathComponent(name)
        let sketchFileURL = sketchFolderURL.appendingPathComponent("\(name).ino")
        
        let defaultCode = """
        void setup() {
          // put your setup code here, to run once:

        }

        void loop() {
          // put your main code here, to run repeatedly:

        }
        """
        
        do {
            // Create the folder
            try FileManager.default.createDirectory(at: sketchFolderURL, withIntermediateDirectories: true, attributes: nil)
            // Write the boilerplate code to the .ino file
            try defaultCode.write(to: sketchFileURL, atomically: true, encoding: .utf8)
            
            DispatchQueue.main.async {
                self.consoleOutput += "Created new sketch at: \(sketchFolderURL.path)\n"
            }
            return sketchFolderURL
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "Error creating sketch: \(error.localizedDescription)\n"
            }
            return nil
        }
    }
    
    // Saves the current code string back to the specified .ino file
    func saveSketchCode(code: String, to fileURL: URL) {
        do {
            try code.write(to: fileURL, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                self.consoleOutput += "Saved sketch to: \(fileURL.path)\n"
            }
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "Error saving sketch: \(error.localizedDescription)\n"
            }
        }
    }

    // Reads the contents of an existing .ino file
    func loadSketchCode(from fileURL: URL) -> String? {
        do {
            let code = try String(contentsOf: fileURL, encoding: .utf8)
            DispatchQueue.main.async {
                self.consoleOutput += "Opened sketch: \(fileURL.path)\n"
            }
            return code
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "Error opening sketch: \(error.localizedDescription)\n"
            }
            return nil
        }
    }

    // The core function that executes the shell command
    func runCommand(arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Run in the background so the app doesn't freeze
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                
                if let output = String(data: data, encoding: .utf8) {
                    // Update UI on the main thread
                    DispatchQueue.main.async {
                        self.consoleOutput += "$ arduino-cli " + arguments.joined(separator: " ") + "\n"
                        self.consoleOutput += output + "\n"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput += "Error: \(error.localizedDescription)\nMake sure arduino-cli is installed at \(self.cliPath)\n"
                }
            }
        }
    }
}

// --- Serial Monitor Connection ---
class SerialMonitorConnection: ObservableObject {
    @Published var output: String = ""
    @Published var isRunning = false
    
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var cliPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundledCLI = appSupport.appendingPathComponent("com.tanoomohal.Blink/bin/arduino-cli")
        if FileManager.default.fileExists(atPath: bundledCLI.path) {
            return bundledCLI.path
        }
        return "/opt/homebrew/bin/arduino-cli"
    }
    
    func start(port: String, baud: String) {
        if isRunning { stop() }
        
        process = Process()
        process?.executableURL = URL(fileURLWithPath: cliPath)
        process?.arguments = ["monitor", "-p", port, "-b", baud]
        
        stdinPipe = Pipe()
        stdoutPipe = Pipe()
        
        process?.standardInput = stdinPipe
        process?.standardOutput = stdoutPipe
        process?.standardError = stdoutPipe
        
        stdoutPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.output += text
            }
        }
        
        process?.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.output += "\n[Serial Monitor Disconnected]\n"
            }
        }
        
        do {
            try process?.run()
            DispatchQueue.main.async {
                self.isRunning = true
                self.output = "Connected to \(port) at \(baud) baud.\n"
            }
        } catch {
            DispatchQueue.main.async {
                self.output = "Failed to start serial monitor: \(error.localizedDescription)\n"
            }
        }
    }
    
    func stop() {
        process?.terminate()
        isRunning = false
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
    }
    
    func send(text: String) {
        let command = text + "\n"
        if let data = command.data(using: .utf8) {
            stdinPipe?.fileHandleForWriting.write(data)
            DispatchQueue.main.async {
                self.output += ">> \(text)\n"
            }
        }
    }
}
