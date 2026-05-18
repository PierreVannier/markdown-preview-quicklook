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
    @State private var selectedTheme = ThemePreferences.current

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

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Preview theme", systemImage: selectedTheme.systemImage)
                    .font(.headline)

                Picker("Preview theme", selection: $selectedTheme) {
                    ForEach(PreviewTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                Text("Reopen Quick Look to refresh an existing preview.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: selectedTheme) { _, newTheme in
            ThemePreferences.current = newTheme
        }
        .padding(24)
        .frame(width: 420)
    }
}
