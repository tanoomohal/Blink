import SwiftUI
import AppKit

struct EditorView: View {
    @Binding var openFiles: [URL]
    @Binding var activeFileURL: URL?
    @Binding var fileContents: [URL: String]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(openFiles, id: \.self) { url in
                    EditorTab(
                        title: url.lastPathComponent,
                        isActive: activeFileURL == url,
                        onSelect: { activeFileURL = url },
                        onClose: { closeFile(url) }
                    )
                }
                Spacer()
            }
            .background(Theme.panelBackground)
            
            Divider()
                .background(Theme.border)
            
            // Editor Content
            if let activeURL = activeFileURL {
                if let content = fileContents[activeURL] {
                    SyntaxTextView(
                        text: Binding(
                            get: { content },
                            set: { newValue in
                                fileContents[activeURL] = newValue
                            }
                        )
                    )
                    .background(Theme.background)
                } else if ["png", "jpg", "jpeg"].contains(activeURL.pathExtension.lowercased()), let nsImage = NSImage(contentsOf: activeURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.background)
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Preview not available")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select a file to edit")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
            }
        }
    }
    
    private func closeFile(_ url: URL) {
        if let index = openFiles.firstIndex(of: url) {
            openFiles.remove(at: index)
            if activeFileURL == url {
                activeFileURL = openFiles.last
            }
        }
    }
}

struct EditorTab: View {
    let title: String
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(isActive ? .primary : .secondary)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(isHovering ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .opacity((isActive || isHovering) ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? Theme.background : Theme.panelBackground)
        .onHover { hover in
            isHovering = hover
        }
        .onTapGesture {
            onSelect()
        }
        // Bottom border indicator for active tab
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(isActive ? Theme.accent : .clear),
            alignment: .top
        )
        // Right border
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Theme.border),
            alignment: .trailing
        )
    }
}

// MARK: - NSTextView Wrapper for Syntax Highlighting

struct SyntaxTextView: NSViewRepresentable {
    @Binding var text: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = NSColor(Theme.background)
        textView.textColor = Theme.plainText
        textView.insertionPointColor = Theme.plainText
        
        // Disable smart quotes/dashes which break code
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        textView.delegate = context.coordinator
        textView.string = text
        
        scrollView.documentView = textView
        
        // Initial highlight
        context.coordinator.highlight(textView.textStorage)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.highlight(textView.textStorage)
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxTextView
        
        let keywordRegex = try! NSRegularExpression(pattern: "\\b(void|int|float|double|char|bool|string|String|if|else|for|while|return|true|false|class|struct|public|private)\\b")
        let stringRegex = try! NSRegularExpression(pattern: "\".*?\"")
        let commentRegex = try! NSRegularExpression(pattern: "//.*|/\\*.*?\\*/", options: .dotMatchesLineSeparators)
        let numberRegex = try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b")
        let funcRegex = try! NSRegularExpression(pattern: "\\b(setup|loop|pinMode|digitalWrite|digitalRead|delay|analogRead|analogWrite|Serial|print|println|begin)\\b")
        
        init(_ parent: SyntaxTextView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            highlight(textView.textStorage)
        }
        
        func highlight(_ textStorage: NSTextStorage?) {
            guard let textStorage = textStorage else { return }
            let string = textStorage.string
            let range = NSRange(location: 0, length: string.utf16.count)
            
            textStorage.beginEditing()
            
            // Reset to default
            textStorage.setAttributes([
                .foregroundColor: Theme.plainText,
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            ], range: range)
            
            // Highlight Numbers
            numberRegex.enumerateMatches(in: string, range: range) { match, _, _ in
                if let r = match?.range { textStorage.addAttribute(.foregroundColor, value: Theme.number, range: r) }
            }
            
            // Highlight Keywords
            keywordRegex.enumerateMatches(in: string, range: range) { match, _, _ in
                if let r = match?.range { textStorage.addAttribute(.foregroundColor, value: Theme.keyword, range: r) }
            }
            
            // Highlight Functions/Built-ins
            funcRegex.enumerateMatches(in: string, range: range) { match, _, _ in
                if let r = match?.range { textStorage.addAttribute(.foregroundColor, value: Theme.keyword, range: r) }
            }
            
            // Highlight Strings
            stringRegex.enumerateMatches(in: string, range: range) { match, _, _ in
                if let r = match?.range { textStorage.addAttribute(.foregroundColor, value: Theme.string, range: r) }
            }
            
            // Highlight Comments
            commentRegex.enumerateMatches(in: string, range: range) { match, _, _ in
                if let r = match?.range { textStorage.addAttribute(.foregroundColor, value: Theme.comment, range: r) }
            }
            
            textStorage.endEditing()
        }
    }
}
