import SwiftUI

struct Theme {
    static let background = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let panelBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let border = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let accent = Color(red: 0.9, green: 0.4, blue: 0.2) // Rust orange
    static let selectionBackground = Color(red: 0.9, green: 0.4, blue: 0.2).opacity(0.3)
    
    // Syntax Highlighting Colors
    static let keyword = NSColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
    static let string = NSColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
    static let comment = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    static let number = NSColor(red: 0.7, green: 0.8, blue: 0.5, alpha: 1.0)
    static let plainText = NSColor.white
}
