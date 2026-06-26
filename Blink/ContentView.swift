import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // Connect our CLI engine to the UI
    @StateObject private var cli = ArduinoCLI()
    @StateObject private var serialMonitor = SerialMonitorConnection()
    
    // Editor State
    @StateObject private var sidebarViewModel = SidebarViewModel()
    @State private var openFiles: [URL] = []
    @State private var activeFileURL: URL?
    @State private var fileContents: [URL: String] = [:]
    
    @State private var currentSketchDirectory: URL?
    
    // Hardware State
    @State private var fqbn: String = ""
    @State private var port: String = ""
    @State private var availableBoards: [String] = []
    @State private var availablePorts: [String] = []
    
    @State private var isShowingBoardPicker = false
    @State private var boardPickerSearchText = ""
    
    var filteredBoards: [String] {
        if boardPickerSearchText.isEmpty {
            return availableBoards
        } else {
            return availableBoards.filter { $0.localizedCaseInsensitiveContains(boardPickerSearchText) }
        }
    }
    
    // Serial Monitor State
    @State private var selectedBottomTab: Int = 0 // 0 = Console, 1 = Serial Monitor
    @State private var serialInput: String = ""
    @State private var selectedBaudRate: String = "9600"
    let baudRates = ["9600", "19200", "38400", "57600", "115200"]
    
    // Library Manager State
    @State private var isShowingLibraryManager = false
    @State private var librarySearchQuery = ""
    @State private var searchResults: [LibraryResult] = []
    @State private var isSearching = false
    @State private var hasPerformedSearch = false
    
    // Board Manager State
    @State private var isShowingBoardManager = false
    @State private var boardSearchQuery = ""
    @State private var boardSearchResults: [CoreResult] = []
    @State private var isSearchingBoards = false
    @State private var hasPerformedBoardSearch = false
    
    // Examples Browser State
    @State private var isShowingExamplesBrowser = false
    @State private var exampleResults: [ExampleResult] = []
    
    // Settings State & AppStorage (Persisted Preferences)
    @State private var isShowingSettings = false
    @AppStorage("sketchbookLocation") var sketchbookLocation: String = "~/Documents/Arduino"
    @AppStorage("editorFontSize") var editorFontSize: Double = 14.0
    @AppStorage("appTheme") var appTheme: String = "System"
    @AppStorage("appLanguage") var appLanguage: String = "English"
    @AppStorage("networkProxy") var networkProxy: String = ""

    // Determine the active color scheme based on user settings
    var activeColorScheme: ColorScheme? {
        switch appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar Area
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // File Management
                    HStack {
                        Button(action: createNewSketchUI) {
                            Label("New", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: openSketchUI) {
                            Label("Open", systemImage: "folder")
                        }
                        
                        Button(action: saveSketchUI) {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .disabled(activeFileURL == nil)
                    }
                    
                    Divider().frame(height: 20)
                    
                    // Hardware Actions
                    HStack {
                        Button(action: {
                            if let dir = currentSketchDirectory {
                                saveSketchUI()
                                cli.compileSketch(fqbn: fqbn, sketchPath: dir.path)
                            }
                        }) {
                            Label("Verify", systemImage: "checkmark.circle")
                        }
                        .disabled(currentSketchDirectory == nil)
                        
                        Button(action: {
                            if let dir = currentSketchDirectory {
                                saveSketchUI()
                                cli.uploadSketch(fqbn: fqbn, port: port, sketchPath: dir.path)
                            }
                        }) {
                            Label("Upload", systemImage: "arrow.right.circle.fill")
                        }
                        .disabled(currentSketchDirectory == nil)
                    }
                    
                    Divider().frame(height: 20)
                    
                    // Hardware Configuration Dropdowns
                    HStack {
                        Button(action: { isShowingBoardPicker.toggle() }) {
                            HStack {
                                Text(fqbn.isEmpty ? "Select Board" : fqbn)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .frame(width: 180)
                        }
                        .popover(isPresented: $isShowingBoardPicker, arrowEdge: .bottom) {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search boards...", text: $boardPickerSearchText)
                                        .textFieldStyle(.plain)
                                }
                                .padding(8)
                                .background(.regularMaterial)
                                
                                Divider()
                                
                                List(filteredBoards, id: \.self) { board in
                                    Button(action: {
                                        fqbn = board
                                        isShowingBoardPicker = false
                                        boardPickerSearchText = ""
                                    }) {
                                        Text(board)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 2)
                                }
                            }
                            .frame(width: 250, height: 300)
                        }
                        
                        Picker("Port", selection: $port) {
                            ForEach(availablePorts, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .frame(width: 180)
                        
                        Button(action: {
                            Task {
                                let (p, b) = await cli.fetchPortsAndBoards()
                                availablePorts = p
                                availableBoards = b
                                if !p.isEmpty && port.isEmpty { port = p.first! }
                                if !b.isEmpty && fqbn.isEmpty { fqbn = b.first! }
                            }
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }

                    Spacer()
                    
                    // Extra Tools & Settings
                    HStack {
                        Button(action: { isShowingExamplesBrowser = true }) {
                            Label("Examples", systemImage: "doc.text.magnifyingglass")
                        }
                        
                        Button(action: { isShowingLibraryManager = true }) {
                            Label("Libraries", systemImage: "books.vertical")
                        }
                        
                        Button(action: { isShowingBoardManager = true }) {
                            Label("Boards", systemImage: "cpu")
                        }
                        
                        Button(action: { isShowingSettings = true }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
                .padding()
            }
            .background(Theme.panelBackground)
            
            Divider().background(Theme.border)
            
            // Main workspace: Resizable Split View
            HSplitView {
                SidebarView(viewModel: sidebarViewModel)
                    .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
                
                VSplitView {
                    EditorView(
                        openFiles: $openFiles,
                        activeFileURL: $activeFileURL,
                        fileContents: $fileContents
                    )
                    .frame(minHeight: 200)
                    
                    OutputConsoleView(
                        selectedTab: $selectedBottomTab,
                        consoleOutput: $cli.consoleOutput,
                        serialMonitor: serialMonitor,
                        serialInput: $serialInput
                    )
                    .frame(minHeight: 150)
                }
            }
        }
        .onChange(of: sidebarViewModel.selectedFileURL) { newURL in
            guard let url = newURL else { return }
            
            // Skip directories
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            if isDir.boolValue { return }
            
            if !openFiles.contains(url) {
                if let code = cli.loadSketchCode(from: url) {
                    openFiles.append(url)
                    fileContents[url] = code
                } else {
                    cli.consoleOutput += "Could not read file at \(url.path)\n"
                    return
                }
            }
            activeFileURL = url
        }
        .frame(minWidth: 850, minHeight: 500)
        .preferredColorScheme(activeColorScheme)
        .onAppear {
            Task {
                let (p, b) = await cli.fetchPortsAndBoards()
                availablePorts = p
                availableBoards = b
                if !p.isEmpty { port = p.first! }
                if !b.isEmpty { fqbn = b.first! }
            }
        }
        .sheet(isPresented: $isShowingLibraryManager) {
            libraryManagerSheet
        }
        .sheet(isPresented: $isShowingBoardManager) {
            boardManagerSheet
        }
        .sheet(isPresented: $isShowingExamplesBrowser) {
            examplesBrowserSheet
        }
        .sheet(isPresented: $isShowingSettings) {
            settingsSheet
        }
    }
    
    // --- Settings UI ---
    
    var settingsSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preferences")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isShowingSettings = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            Form {
                Section(header: Text("Workspace").font(.subheadline).foregroundColor(.secondary)) {
                    TextField("Sketchbook Location:", text: $sketchbookLocation)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Language:", selection: $appLanguage) {
                        Text("English").tag("English")
                        Text("Español").tag("Español")
                        Text("Français").tag("Français")
                        Text("Deutsch").tag("Deutsch")
                    }
                    .pickerStyle(.menu)
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Editor & Theme").font(.subheadline).foregroundColor(.secondary)) {
                    Picker("Theme:", selection: $appTheme) {
                        Text("System Default").tag("System")
                        Text("Light Mode").tag("Light")
                        Text("Dark Mode").tag("Dark")
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Slider(value: $editorFontSize, in: 10...30, step: 1) {
                            Text("Font Size:")
                        }
                        Text("\(Int(editorFontSize)) pt")
                            .frame(width: 40, alignment: .leading)
                    }
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Network").font(.subheadline).foregroundColor(.secondary)) {
                    TextField("Proxy URL:", text: $networkProxy)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(width: 500, height: 400)
        .background(Theme.panelBackground)
    }
    
    // --- Library Manager UI ---
    
    var libraryManagerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Library Manager")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isShowingLibraryManager = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search libraries (e.g., FastLED, WiFiManager)...", text: $librarySearchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch(query: librarySearchQuery)
                        }
                    
                    Button("Search") {
                        performSearch(query: librarySearchQuery)
                    }
                    .disabled(librarySearchQuery.isEmpty || isSearching)
                }
                
                HStack(spacing: 12) {
                    Text("Quick Find:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Arduino Official") {
                        librarySearchQuery = "arduino"
                        performSearch(query: "arduino")
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .disabled(isSearching)
                    
                    Button("Espressif Systems") {
                        librarySearchQuery = "espressif"
                        performSearch(query: "espressif")
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                    .disabled(isSearching)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasPerformedSearch {
                List {
                    Section(header: Text("Search Results").font(.subheadline)) {
                        if searchResults.isEmpty {
                            Text("No results found.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(searchResults) { lib in
                                libraryRow(name: lib.name, description: lib.sentence ?? "No description provided.", version: "Latest")
                            }
                        }
                    }
                }
            } else {
                List {
                    Section(header: Text("Popular Libraries").font(.subheadline)) {
                        libraryRow(name: "FastLED", description: "Multi-color LED animation library.", version: "3.6.0")
                        libraryRow(name: "WiFiManager", description: "ESP8266/ESP32 WiFi Connection manager with web captive portal.", version: "2.0.16-rc.2")
                        libraryRow(name: "PubSubClient", description: "A client library for MQTT messaging.", version: "2.8.0")
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button(action: installZipLibraryUI) {
                    Label("Install Library from .ZIP...", systemImage: "doc.zipper")
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial)
        }
        .frame(width: 500, height: 450)
        .background(.regularMaterial)
    }
    
    func libraryRow(name: String, description: String, version: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline)
                Text(description).font(.subheadline).foregroundColor(.secondary)
                Text("Version: \(version)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button("Install") {
                cli.runCommand(arguments: ["lib", "install", name])
                isShowingLibraryManager = false
            }
        }
        .padding(.vertical, 4)
    }
    
    // --- Board Manager UI ---
    
    var boardManagerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Board Manager")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isShowingBoardManager = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search cores (e.g., esp32, avr)...", text: $boardSearchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performBoardSearch(query: boardSearchQuery)
                        }
                    
                    Button("Search") {
                        performBoardSearch(query: boardSearchQuery)
                    }
                    .disabled(boardSearchQuery.isEmpty || isSearchingBoards)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            if isSearchingBoards {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasPerformedBoardSearch {
                List {
                    Section(header: Text("Search Results").font(.subheadline)) {
                        if boardSearchResults.isEmpty {
                            Text("No results found.")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(boardSearchResults) { core in
                                coreRow(core: core)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("Search for a core to install.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 500, height: 450)
        .background(.regularMaterial)
    }
    
    func coreRow(core: CoreResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(core.id).font(.headline)
                Text(core.maintainer ?? "Unknown").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Button("Install") {
                cli.installCore(id: core.id)
                isShowingBoardManager = false
            }
        }
        .padding(.vertical, 4)
    }
    
    func performBoardSearch(query: String) {
        guard !query.isEmpty else { return }
        isSearchingBoards = true
        hasPerformedBoardSearch = true
        
        Task {
            let results = await cli.searchCoresJSON(query: query)
            await MainActor.run {
                self.boardSearchResults = results
                self.isSearchingBoards = false
            }
        }
    }
    
    // --- Examples Browser UI ---
    
    var examplesBrowserSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Library Examples")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isShowingExamplesBrowser = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            List {
                if exampleResults.isEmpty {
                    Text("Loading examples...")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(exampleResults) { libExample in
                        Section(header: Text(libExample.library.name)) {
                            ForEach(libExample.library.examples, id: \.self) { examplePath in
                                let url = URL(fileURLWithPath: examplePath)
                                let name = url.lastPathComponent
                                Button(action: {
                                    let inoURL = url.appendingPathComponent("\(name).ino")
                                    if let loadedCode = cli.loadSketchCode(from: inoURL) {
                                        currentSketchDirectory = url
                                        sidebarViewModel.loadDirectory(url: url)
                                        
                                        openFiles = [inoURL]
                                        fileContents[inoURL] = loadedCode
                                        activeFileURL = inoURL
                                        
                                        isShowingExamplesBrowser = false
                                    }
                                }) {
                                    Text(name)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 500)
        .background(.regularMaterial)
        .onAppear {
            loadExamples()
        }
    }
    
    func loadExamples() {
        Task {
            let results = await cli.getExamplesJSON()
            await MainActor.run {
                self.exampleResults = results
            }
        }
    }
    // --- UI Logic Methods ---
    
    func createNewSketchUI() {
        let panel = NSSavePanel()
        panel.title = "Create New Sketch"
        panel.nameFieldStringValue = "MySketch"
        panel.prompt = "Create"
        
        if panel.runModal() == .OK, let url = panel.url {
            let name = url.lastPathComponent
            let saveDir = url.deletingLastPathComponent()
            
            if let newDir = cli.createNewSketch(name: name, saveDirectory: saveDir) {
                currentSketchDirectory = newDir
                sidebarViewModel.loadDirectory(url: newDir)
                
                let fileURL = newDir.appendingPathComponent("\(name).ino")
                let initialCode = "void setup() {\n  // put your setup code here, to run once:\n\n}\n\nvoid loop() {\n  // put your main code here, to run repeatedly:\n\n}\n"
                
                openFiles = [fileURL]
                fileContents[fileURL] = initialCode
                activeFileURL = fileURL
            }
        }
    }
    
    func openSketchUI() {
        let panel = NSOpenPanel()
        panel.title = "Open Sketch"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            let fileURL: URL
            let dirURL: URL
            
            if url.hasDirectoryPath {
                dirURL = url
                let sketchName = url.lastPathComponent
                fileURL = url.appendingPathComponent("\(sketchName).ino")
            } else {
                fileURL = url
                dirURL = url.deletingLastPathComponent()
            }
            
            if let loadedCode = cli.loadSketchCode(from: fileURL) {
                currentSketchDirectory = dirURL
                sidebarViewModel.loadDirectory(url: dirURL)
                
                openFiles = [fileURL]
                fileContents[fileURL] = loadedCode
                activeFileURL = fileURL
            } else {
                cli.consoleOutput += "Could not find a valid .ino file at \(fileURL.path)\n"
            }
        }
    }
    
    func saveSketchUI() {
        for (url, content) in fileContents {
            cli.saveSketchCode(code: content, to: url)
        }
        cli.consoleOutput += "Saved all open files.\n"
    }
    
    func installZipLibraryUI() {
        let panel = NSOpenPanel()
        panel.title = "Select Library .ZIP"
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            cli.runCommand(arguments: ["lib", "install", "--zip-path", url.path])
            isShowingLibraryManager = false
        }
    }
    
    func performSearch(query: String) {
        guard !query.isEmpty else { return }
        isSearching = true
        hasPerformedSearch = true
        
        Task {
            let results = await cli.searchLibrariesJSON(query: query)
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }
}

