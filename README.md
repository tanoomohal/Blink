# Blink ⚡️

Blink is a fast, lightweight, and native macOS Integrated Development Environment (IDE) for Arduino and microcontrollers. Built entirely with SwiftUI, Blink leverages the power of `arduino-cli` under the hood to deliver a seamless, modern, and beautiful development experience for hardware enthusiasts and professionals alike.

## Features ✨

*   **Native macOS Experience:** Built from the ground up using SwiftUI, providing a beautiful, responsive, and familiar interface that feels right at home on your Mac.
*   **Powered by `arduino-cli`:** Uses the robust Arduino Command Line Interface for core operations, ensuring high compatibility and performance. It works seamlessly with a bundled CLI or a Homebrew installation.
*   **Smart Board Discovery:** Automatically detects connected boards and available ports in real-time.
*   **Code Editing & Compilation:** Create new sketches, edit your code, verify (compile), and upload to your microcontroller with just a click.
*   **Integrated Serial Monitor:** Communicate with your board directly within the app. Start, stop, and send commands over serial connections effortlessly.
*   **Real-time Serial Plotter:** Automatically parses incoming comma-separated numerical data from the serial monitor and plots it in a dynamic, real-time graph.
*   **Core & Library Management:** Search, install, and manage Arduino cores (platforms) and libraries directly from the UI.
*   **Examples Library:** Easily browse and load examples for your installed libraries.

## Requirements 💻

*   macOS 13.0 or later (Recommended)
*   Xcode (for building the project from source)
*   `arduino-cli` (The app can use a bundled version or look for it at `/opt/homebrew/bin/arduino-cli`)

## Installation 🚀

### For Users
*Currently in development. Pre-built binaries will be available in future releases.*

### For Developers
1. Clone the repository:
   ```bash
   git clone https://github.com/tanoomohal/Blink.git
   ```
2. Open `Blink.xcodeproj` in Xcode.
3. Wait for Swift Package dependencies to resolve.
4. Select your Mac as the run destination.
5. Hit **Run** (`Cmd + R`) to build and launch the app.

## Architecture & Technologies 🛠️

*   **UI Framework:** SwiftUI for declarative, modern UI design.
*   **Reactive Programming:** Combine framework for handling data streams, especially for real-time serial plotting and terminal output parsing.
*   **Backend:** `arduino-cli` driven via macOS `Process` and `Pipe` APIs to execute commands asynchronously without blocking the UI thread.
*   **Architecture Pattern:** MVVM (Model-View-ViewModel) utilizing `@State`, `@Binding`, and `@EnvironmentObject` to manage the IDE's state efficiently.

## Core Components 🧩

*   **`BlinkEngine`**: The heart of the IDE. It acts as a wrapper around the `arduino-cli`, managing process execution, parsing JSON responses for boards/cores/libraries, and handling file system operations for sketches.
*   **`SerialMonitorConnection`**: Manages the persistent serial connection, piping `stdin`/`stdout` directly to the `arduino-cli monitor` command, and intelligently parsing output for the Serial Plotter.
*   **`EditorView`**: The main code editing interface.
*   **`SerialPlotterView`**: Renders real-time graphs from serial data streams.

## Contributing 🤝

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/tanoomohal/Blink/issues) if you want to contribute.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License 📄

Distributed under the MIT License. See `LICENSE` for more information.

---
*Built with ❤️ for the maker community.*
