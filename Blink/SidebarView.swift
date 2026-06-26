import SwiftUI
import Combine

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    var url: URL
    var isDirectory: Bool
    var children: [FileItem]?
    
    var name: String {
        url.lastPathComponent
    }
}

class SidebarViewModel: ObservableObject {
    @Published var rootItems: [FileItem] = []
    @Published var selectedFileURL: URL?
    
    func loadDirectory(url: URL) {
        rootItems = [buildTree(for: url)]
    }
    
    private func buildTree(for url: URL) -> FileItem {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        
        if isDir.boolValue {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
                let children = contents.map { buildTree(for: $0) }.sorted { $0.name < $1.name }
                return FileItem(url: url, isDirectory: true, children: children)
            } catch {
                return FileItem(url: url, isDirectory: true, children: [])
            }
        } else {
            return FileItem(url: url, isDirectory: false, children: nil)
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SKETCHBOOK")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            Divider()
                .background(Theme.border)
            
            List(selection: $viewModel.selectedFileURL) {
                ForEach(viewModel.rootItems) { item in
                    OutlineGroup(item, children: \.children) { child in
                        HStack {
                            Image(systemName: child.isDirectory ? "folder.fill" : "doc.text")
                                .foregroundColor(child.isDirectory ? .orange : .secondary)
                            Text(child.name)
                                .foregroundColor(.primary)
                        }
                        .tag(child.url)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Theme.panelBackground)
        }
        .background(Theme.panelBackground)
    }
}
