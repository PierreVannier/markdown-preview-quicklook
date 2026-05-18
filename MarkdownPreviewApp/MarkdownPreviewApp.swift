import SwiftUI

@main
struct MarkdownPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            InstallStatusView()
        }
        .windowResizability(.contentSize)
    }
}

private struct InstallStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Markdown Preview")
                        .font(.title2.weight(.semibold))
                    Text("Finder Quick Look renderer is installed.")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Select a .md file in Finder and press Space.", systemImage: "space")
                Label("Use Finder's Preview pane for click-to-preview.", systemImage: "sidebar.right")
            }
            .font(.callout)
        }
        .padding(24)
        .frame(width: 420)
    }
}
