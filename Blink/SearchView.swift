import SwiftUI
import Combine

struct SearchResult: Identifiable {
    let id = UUID()
    let fileURL: URL
    let line: Int
    let text: String
}

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [SearchResult] = []
    @Published var isSearching: Bool = false
    
    func performSearch(in directory: URL?) {
        guard let dir = directory, !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        results = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var newResults: [SearchResult] = []
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            
            let allowedExtensions = ["ino", "cpp", "h", "c"]
            
            while let url = enumerator?.nextObject() as? URL {
                guard allowedExtensions.contains(url.pathExtension.lowercased()) else { continue }
                
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    let lines = content.components(separatedBy: .newlines)
                    for (index, line) in lines.enumerated() {
                        if line.localizedCaseInsensitiveContains(self.query) {
                            newResults.append(SearchResult(fileURL: url, line: index + 1, text: line.trimmingCharacters(in: .whitespaces)))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.results = newResults
                self.isSearching = false
            }
        }
    }
}

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    var currentDirectory: URL?
    var onSelectResult: (URL) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SEARCH")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            Divider()
                .background(Theme.border)
            
            VStack(spacing: 8) {
                TextField("Search in Workspace...", text: $viewModel.query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.performSearch(in: currentDirectory)
                    }
                
                Button(action: {
                    viewModel.performSearch(in: currentDirectory)
                }) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                }
                .disabled(viewModel.query.isEmpty || viewModel.isSearching)
            }
            .padding()
            
            Divider()
                .background(Theme.border)
            
            if viewModel.isSearching {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                Text("No results found.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List(viewModel.results) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.fileURL.lastPathComponent)
                            .font(.system(size: 12, weight: .bold))
                        Text(result.text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectResult(result.fileURL)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            Spacer()
        }
        .background(Theme.panelBackground)
        .onChange(of: currentDirectory) { _ in
            viewModel.results = []
            viewModel.query = ""
        }
    }
}
