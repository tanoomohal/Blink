import SwiftUI

enum SidebarState: String, CaseIterable {
    case explorer = "Explorer"
    case search = "Search"
    case git = "Source Control"
    
    var iconName: String {
        switch self {
        case .explorer: return "doc.on.doc"
        case .search: return "magnifyingglass"
        case .git: return "arrow.triangle.branch"
        }
    }
}

struct ActivityBar: View {
    @Binding var selectedState: SidebarState
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(SidebarState.allCases, id: \.self) { state in
                Button(action: {
                    selectedState = state
                }) {
                    Image(systemName: state.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(selectedState == state ? .primary : .secondary)
                        .frame(width: 45, height: 45)
                }
                .buttonStyle(.plain)
                .help(state.rawValue)
            }
            Spacer()
        }
        .padding(.top, 20)
        .frame(width: 50)
        .background(Theme.panelBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Theme.border),
            alignment: .trailing
        )
    }
}
