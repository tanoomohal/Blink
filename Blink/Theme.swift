import SwiftUI

struct Theme {
    static let background = Color(NSColor.textBackgroundColor)
    static let panelBackground = Color(NSColor.windowBackgroundColor)
    static let border = Color(NSColor.separatorColor)
    static let accent = Color(red: 0.9, green: 0.4, blue: 0.2) // Rust orange
    static let selectionBackground = Color(red: 0.9, green: 0.4, blue: 0.2).opacity(0.3)
    
    // Syntax Highlighting Colors
    static let keyword = NSColor.systemBlue
    static let string = NSColor.systemOrange
    static let comment = NSColor.systemGray
    static let number = NSColor.systemGreen
    static let plainText = NSColor.textColor
}
