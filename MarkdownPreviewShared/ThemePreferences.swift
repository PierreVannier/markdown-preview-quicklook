import Foundation
import Darwin

enum PreviewTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }

    var htmlClass: String {
        "theme-\(rawValue)"
    }
}

enum ThemePreferences {
    static let appIdentifier = "local.pierrevannier.MarkdownPreview"
    static let extensionIdentifier = "local.pierrevannier.MarkdownPreview.Extension"
    static let key = "PreviewTheme"

    static var preferenceFileURL: URL {
        realHomeDirectory
            .appendingPathComponent("Library/Application Support/Markdown Preview/theme.txt")
    }

    static var current: PreviewTheme {
        get {
            if let rawValue = readSharedPreference(),
               let theme = PreviewTheme(rawValue: rawValue) {
                return theme
            }

            let preferenceKey = key as NSString

            for domain in [appIdentifier, extensionIdentifier] {
                if let rawValue = CFPreferencesCopyAppValue(preferenceKey, domain as NSString) as? String,
                   let theme = PreviewTheme(rawValue: rawValue) {
                    return theme
                }
            }

            return .system
        }
        set {
            let preferenceKey = key as NSString
            let rawValue = newValue.rawValue as NSString

            writeSharedPreference(newValue.rawValue)

            for domain in [appIdentifier, extensionIdentifier] {
                let preferenceDomain = domain as NSString
                CFPreferencesSetAppValue(preferenceKey, rawValue, preferenceDomain)
                CFPreferencesAppSynchronize(preferenceDomain)
            }
        }
    }

    private static var realHomeDirectory: URL {
        if let passwordEntry = getpwuid(getuid()),
           let homeDirectory = passwordEntry.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: homeDirectory), isDirectory: true)
        }

        return FileManager.default.homeDirectoryForCurrentUser
    }

    private static func readSharedPreference() -> String? {
        guard let rawValue = try? String(contentsOf: preferenceFileURL, encoding: .utf8) else {
            return nil
        }

        return rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func writeSharedPreference(_ rawValue: String) {
        let url = preferenceFileURL

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try "\(rawValue)\n".write(to: url, atomically: true, encoding: .utf8)
        } catch {
            // The CFPreferences writes below keep the setting usable if the file write is denied.
        }
    }
}
