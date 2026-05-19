import AppKit
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
    @State private var isResettingQuickLook = false
    @State private var maintenanceMessage: MaintenanceMessage?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Markdown Preview")
                        .font(.title2.weight(.semibold))
                    Text("Finder Quick Look renderer is installed.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(extensionStatus.title, systemImage: extensionStatus.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(extensionStatus.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(extensionStatus.tint.opacity(0.12), in: Capsule())
            }

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

                Text("Saved to \(ThemePreferences.preferenceFileURL.path)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    StatusRow(
                        title: "Extension bundle",
                        value: extensionStatus.detail,
                        systemImage: extensionStatus.systemImage,
                        tint: extensionStatus.tint
                    )

                    StatusRow(
                        title: "Current theme",
                        value: selectedTheme.displayName,
                        systemImage: selectedTheme.systemImage,
                        tint: .teal
                    )

                    if let maintenanceMessage {
                        StatusRow(
                            title: "Quick Look",
                            value: maintenanceMessage.text,
                            systemImage: maintenanceMessage.systemImage,
                            tint: maintenanceMessage.tint
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await resetQuickLook() }
                } label: {
                    Label(isResettingQuickLook ? "Resetting..." : "Reset Quick Look", systemImage: "arrow.clockwise")
                }
                .disabled(isResettingQuickLook)

                Button {
                    openPreferencesFolder()
                } label: {
                    Label("Open Settings Folder", systemImage: "folder")
                }

                Spacer()
            }
            .buttonStyle(.bordered)
        }
        .onChange(of: selectedTheme) { _, newTheme in
            ThemePreferences.current = newTheme
            maintenanceMessage = .info("Reopen the Finder preview to apply \(newTheme.displayName).")
        }
        .padding(24)
        .frame(width: 520)
    }

    private var extensionStatus: ExtensionStatus {
        guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent("Markdown Preview Extension.appex") else {
            return .missing
        }

        return FileManager.default.fileExists(atPath: url.path) ? .available(url) : .missing
    }

    @MainActor
    private func resetQuickLook() async {
        isResettingQuickLook = true
        maintenanceMessage = .info("Resetting Quick Look cache...")

        let result = await QuickLookMaintenance.resetCache()

        isResettingQuickLook = false
        maintenanceMessage = result
    }

    private func openPreferencesFolder() {
        let folder = ThemePreferences.preferenceFileURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            NSWorkspace.shared.activateFileViewerSelecting([folder])
        } catch {
            maintenanceMessage = .error("Could not open settings folder.")
        }
    }
}

private struct StatusRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 18)

            Text(title)
                .fontWeight(.medium)

            Spacer(minLength: 16)

            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.callout)
    }
}

private enum ExtensionStatus {
    case available(URL)
    case missing

    var title: String {
        switch self {
        case .available:
            return "Ready"
        case .missing:
            return "Missing"
        }
    }

    var detail: String {
        switch self {
        case .available(let url):
            return url.lastPathComponent
        case .missing:
            return "Extension bundle not found"
        }
    }

    var systemImage: String {
        switch self {
        case .available:
            return "checkmark.seal.fill"
        case .missing:
            return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .available:
            return .green
        case .missing:
            return .orange
        }
    }
}

private struct MaintenanceMessage: Sendable {
    let text: String
    let kind: MaintenanceMessageKind

    var systemImage: String {
        switch kind {
        case .info:
            return "info.circle"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch kind {
        case .info:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    static func info(_ text: String) -> MaintenanceMessage {
        MaintenanceMessage(text: text, kind: .info)
    }

    static func success(_ text: String) -> MaintenanceMessage {
        MaintenanceMessage(text: text, kind: .success)
    }

    static func error(_ text: String) -> MaintenanceMessage {
        MaintenanceMessage(text: text, kind: .error)
    }
}

private enum MaintenanceMessageKind: Sendable {
    case info
    case success
    case error
}

private enum QuickLookMaintenance {
    static func resetCache() async -> MaintenanceMessage {
        await Task.detached {
            let reset = runQLManage(arguments: ["-r"])
            let cache = runQLManage(arguments: ["-r", "cache"])

            if reset.exitCode == 0, cache.exitCode == 0 {
                return .success("Quick Look cache reset.")
            }

            let output = [reset.output, cache.output]
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return .error(output.isEmpty ? "Quick Look reset failed." : output)
        }
        .value
    }

    private static func runQLManage(arguments: [String]) -> CommandResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return CommandResult(
                exitCode: process.terminationStatus,
                output: String(decoding: data, as: UTF8.self)
            )
        } catch {
            return CommandResult(exitCode: 1, output: error.localizedDescription)
        }
    }
}

private struct CommandResult {
    let exitCode: Int32
    let output: String
}
