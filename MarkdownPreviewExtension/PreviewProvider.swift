import CoreGraphics
import Foundation
import OSLog
import Quartz
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let logger = Logger(subsystem: "local.pierrevannier.MarkdownPreview", category: "Preview")

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let theme = ThemePreferences.current
        logger.info("Rendering Markdown preview using \(theme.rawValue, privacy: .public) theme")

        let html = MarkdownHTMLRenderer.renderFile(at: request.fileURL, theme: theme)
        let data = Data(html.utf8)

        return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 920, height: 1180)) { reply in
            reply.stringEncoding = .utf8
            return data
        }
    }
}

private enum MarkdownHTMLRenderer {
    static func renderFile(at url: URL, theme: PreviewTheme) -> String {
        let data = (try? Data(contentsOf: url)) ?? Data()
        let markdown = decode(data)
        let fileName = escapeHTML(url.lastPathComponent)
        let content = render(markdown, baseURL: url.deletingLastPathComponent())
        let themeClass = escapeHTML(theme.htmlClass)

        return """
        <!doctype html>
        <html lang="en" class="\(themeClass)">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(fileName)</title>
        <style>
        :root,
        :root.theme-light {
          color-scheme: light;
          --bg: #f5f7f8;
          --paper: #ffffff;
          --text: #17202a;
          --muted: #64717d;
          --subtle: #d8dee4;
          --accent: #167267;
          --accent-strong: #0f5f57;
          --inline-code-bg: #edf3f1;
          --inline-code-text: #0d504a;
          --code-bg: #111827;
          --code-text: #edf5f3;
          --table-stripe: #f7faf9;
          --quote-bg: #f1f7f5;
        }

        :root.theme-system {
          color-scheme: light dark;
        }

        :root.theme-dark {
          color-scheme: dark;
          --bg: #111417;
          --paper: #1b2025;
          --text: #e7ecef;
          --muted: #a6b0b9;
          --subtle: #303941;
          --accent: #66c7b8;
          --accent-strong: #89d8cc;
          --inline-code-bg: #253330;
          --inline-code-text: #a8eee2;
          --code-bg: #090d12;
          --code-text: #e7f1ee;
          --table-stripe: #20272d;
          --quote-bg: #202b29;
        }

        @media (prefers-color-scheme: dark) {
          :root.theme-system {
            color-scheme: dark;
            --bg: #111417;
            --paper: #1b2025;
            --text: #e7ecef;
            --muted: #a6b0b9;
            --subtle: #303941;
            --accent: #66c7b8;
            --accent-strong: #89d8cc;
            --inline-code-bg: #253330;
            --inline-code-text: #a8eee2;
            --code-bg: #090d12;
            --code-text: #e7f1ee;
            --table-stripe: #20272d;
            --quote-bg: #202b29;
          }
        }

        * { box-sizing: border-box; }
        html, body { margin: 0; min-height: 100%; }
        body {
          background: var(--bg);
          color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Arial, sans-serif;
          font-size: 16px;
          line-height: 1.65;
        }
        .shell {
          max-width: 920px;
          margin: 0 auto;
          padding: 34px 42px 64px;
        }
        .paper {
          background: var(--paper);
          border: 1px solid color-mix(in srgb, var(--subtle) 78%, transparent);
          border-radius: 16px;
          box-shadow: 0 18px 44px rgba(21, 29, 36, 0.10);
          overflow: hidden;
        }
        .filebar {
          display: flex;
          align-items: center;
          gap: 12px;
          min-height: 62px;
          padding: 16px 28px;
          border-bottom: 1px solid var(--subtle);
          color: var(--muted);
          font-size: 13px;
          font-weight: 600;
        }
        .filedot {
          width: 11px;
          height: 11px;
          border-radius: 50%;
          background: var(--accent);
          box-shadow: 0 0 0 4px color-mix(in srgb, var(--accent) 14%, transparent);
          flex: 0 0 auto;
        }
        .filename {
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .markdown-body {
          padding: 34px 46px 52px;
          overflow-wrap: break-word;
        }
        .empty {
          color: var(--muted);
          font-size: 15px;
          margin: 0;
        }
        h1, h2, h3, h4, h5, h6 {
          color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", Arial, sans-serif;
          line-height: 1.16;
          margin: 1.4em 0 0.55em;
          letter-spacing: 0;
        }
        h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
        h1 { font-size: 2.45rem; font-weight: 760; padding-bottom: 0.28em; border-bottom: 1px solid var(--subtle); }
        h2 { font-size: 1.72rem; font-weight: 730; padding-bottom: 0.18em; border-bottom: 1px solid color-mix(in srgb, var(--subtle) 72%, transparent); }
        h3 { font-size: 1.28rem; font-weight: 700; }
        h4 { font-size: 1.08rem; font-weight: 700; color: color-mix(in srgb, var(--text) 88%, var(--muted)); }
        h5, h6 { font-size: 0.96rem; font-weight: 700; color: var(--muted); text-transform: uppercase; }
        p { margin: 0 0 1.05em; }
        a { color: var(--accent-strong); text-decoration-thickness: 0.09em; text-underline-offset: 0.18em; }
        strong { font-weight: 720; }
        em { font-style: italic; }
        s { color: var(--muted); }
        code {
          font-family: "SF Mono", Menlo, Monaco, Consolas, monospace;
          font-size: 0.92em;
        }
        p code, .list-item code, blockquote code, td code, th code {
          background: var(--inline-code-bg);
          color: var(--inline-code-text);
          border: 1px solid color-mix(in srgb, var(--accent) 16%, transparent);
          border-radius: 5px;
          padding: 0.12em 0.36em;
        }
        .code-block {
          position: relative;
          margin: 1.35em 0;
        }
        .code-lang {
          position: absolute;
          top: 11px;
          right: 14px;
          z-index: 1;
          color: color-mix(in srgb, var(--code-text) 65%, transparent);
          font-family: "SF Mono", Menlo, Monaco, Consolas, monospace;
          font-size: 11px;
          letter-spacing: 0;
          text-transform: uppercase;
        }
        pre {
          margin: 0;
          padding: 19px 20px;
          overflow: auto;
          white-space: pre-wrap;
          word-break: normal;
          border-radius: 10px;
          background: var(--code-bg);
          color: var(--code-text);
          border: 1px solid color-mix(in srgb, var(--code-text) 10%, transparent);
        }
        .code-lang + pre { padding-top: 34px; }
        blockquote {
          margin: 1.25em 0;
          padding: 0.25em 0 0.25em 1.05em;
          border-left: 4px solid var(--accent);
          background: var(--quote-bg);
          color: color-mix(in srgb, var(--text) 80%, var(--muted));
          border-radius: 0 8px 8px 0;
        }
        blockquote > :last-child { margin-bottom: 0; }
        figure {
          margin: 1.4em 0;
        }
        figure img {
          display: block;
          max-width: 100%;
          max-height: 720px;
          border: 1px solid var(--subtle);
          border-radius: 10px;
          background: var(--paper);
        }
        figcaption {
          margin-top: 0.55em;
          color: var(--muted);
          font-size: 0.9em;
          text-align: center;
        }
        .list-item {
          --depth: 0;
          display: grid;
          grid-template-columns: 2.15rem minmax(0, 1fr);
          gap: 0.35rem;
          margin: 0.32em 0 0.32em calc(var(--depth) * 1.35rem);
        }
        .marker {
          color: var(--accent);
          font-weight: 720;
          text-align: right;
          user-select: none;
        }
        .task-marker {
          display: flex;
          justify-content: flex-end;
          padding-top: 0.3em;
        }
        .task-checkbox {
          display: inline-grid;
          width: 1.05em;
          height: 1.05em;
          place-items: center;
          border: 1.5px solid var(--accent);
          border-radius: 4px;
          color: var(--paper);
          background: transparent;
          font-size: 0.78em;
          line-height: 1;
        }
        .task-checkbox.checked {
          background: var(--accent);
        }
        .task-checkbox.checked::after {
          content: "\\2713";
          font-weight: 800;
        }
        .li-content > :last-child { margin-bottom: 0; }
        table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          margin: 1.35em 0;
          border: 1px solid var(--subtle);
          border-radius: 10px;
          overflow: hidden;
          font-size: 0.95em;
        }
        th, td {
          padding: 0.72rem 0.82rem;
          border-right: 1px solid var(--subtle);
          border-bottom: 1px solid var(--subtle);
          vertical-align: top;
        }
        th:last-child, td:last-child { border-right: 0; }
        tr:last-child td { border-bottom: 0; }
        th {
          background: color-mix(in srgb, var(--accent) 10%, var(--paper));
          color: var(--text);
          font-weight: 720;
        }
        tbody tr:nth-child(even) td { background: var(--table-stripe); }
        hr {
          border: 0;
          border-top: 1px solid var(--subtle);
          margin: 2em 0;
        }
        @media (max-width: 720px) {
          .shell { padding: 18px; }
          .markdown-body { padding: 26px 24px 38px; }
          h1 { font-size: 2rem; }
          h2 { font-size: 1.45rem; }
        }
        </style>
        </head>
        <body>
          <div class="shell">
            <section class="paper">
              <div class="filebar">
                <span class="filedot"></span>
                <span class="filename">\(fileName)</span>
              </div>
              <article class="markdown-body">
                \(content)
              </article>
            </section>
          </div>
        </body>
        </html>
        """
    }

    private static func render(_ markdown: String, baseURL: URL) -> String {
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return #"<p class="empty">This Markdown file is empty.</p>"#
        }

        let segments = markdownSegments(from: markdown)
        if segments.count > 1 || segments.contains(where: \.isImage) {
            let html = segments.map { segment in
                switch segment {
                case .markdown(let markdown):
                    return renderMarkdown(markdown)
                case .image(let image):
                    return renderImage(image, baseURL: baseURL)
                }
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

            return html.isEmpty ? #"<p class="empty">This Markdown file is empty.</p>"# : html
        }

        return renderMarkdown(markdown)
    }

    private static func renderMarkdown(_ markdown: String) -> String {
        do {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
            let parsed = try AttributedString(markdown: markdown, options: options)
            let fragments = fragments(from: parsed)

            if fragments.isEmpty {
                return #"<p class="empty">This Markdown file is empty.</p>"#
            }

            return renderFragments(fragments)
        } catch {
            return renderCodeBlock(markdown, language: nil)
        }
    }

    private static func decode(_ data: Data) -> String {
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }
        if let string = String(data: data, encoding: .macOSRoman) {
            return string
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func fragments(from parsed: AttributedString) -> [Fragment] {
        parsed.runs.compactMap { run in
            let text = String(parsed.characters[run.range])
            guard !text.isEmpty else { return nil }

            return Fragment(
                text: text,
                presentationIntent: run.presentationIntent,
                inlineIntent: run.inlinePresentationIntent,
                link: run.link
            )
        }
    }

    private static func renderFragments(_ fragments: [Fragment]) -> String {
        var html: [String] = []
        var index = fragments.startIndex

        while index < fragments.endIndex {
            let meta = BlockMetadata(fragments[index].presentationIntent)

            if let tableID = meta.tableID {
                var tableFragments: [Fragment] = []
                while index < fragments.endIndex, BlockMetadata(fragments[index].presentationIntent).tableID == tableID {
                    tableFragments.append(fragments[index])
                    index += 1
                }
                html.append(renderTable(tableFragments))
                continue
            }

            let intent = fragments[index].presentationIntent
            var blockFragments: [Fragment] = []
            while index < fragments.endIndex,
                  fragments[index].presentationIntent == intent,
                  BlockMetadata(fragments[index].presentationIntent).tableID == nil {
                blockFragments.append(fragments[index])
                index += 1
            }

            html.append(renderBlock(blockFragments, metadata: meta))
        }

        return html.joined(separator: "\n")
    }

    private static func renderBlock(_ fragments: [Fragment], metadata: BlockMetadata) -> String {
        if metadata.isThematicBreak {
            return "<hr>"
        }

        if let language = metadata.codeLanguage {
            return renderCodeBlock(fragments.map(\.text).joined(), language: language)
        }

        let (taskState, contentFragments) = taskListStateAndContent(from: fragments)
        let body = contentFragments.map(renderInline).joined()
        let rendered: String

        if let level = metadata.headingLevel {
            let tag = "h\(min(max(level, 1), 6))"
            rendered = "<\(tag)>\(body)</\(tag)>"
        } else if let marker = metadata.listMarker {
            let depth = max(metadata.indentationLevel - 1, 0)
            let markerHTML = taskState.map(renderTaskMarker) ?? (metadata.isUnorderedList ? "&bull;" : escapeHTML(marker))
            rendered = """
            <div class="list-item" style="--depth: \(depth);">
              <span class="marker">\(markerHTML)</span>
              <div class="li-content">\(body)</div>
            </div>
            """
        } else {
            rendered = "<p>\(body)</p>"
        }

        if metadata.isBlockQuote {
            return "<blockquote>\(rendered)</blockquote>"
        }

        return rendered
    }

    private static func markdownSegments(from markdown: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        var markdownLines: [String] = []
        var isInsideFence = false

        func flushMarkdownLines() {
            let block = markdownLines.joined(separator: "\n")
            if !block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.markdown(block))
            }
            markdownLines.removeAll()
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if !isInsideFence, let image = MarkdownImage(line: line) {
                flushMarkdownLines()
                segments.append(.image(image))
                continue
            }

            markdownLines.append(line)

            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                isInsideFence.toggle()
            }
        }

        flushMarkdownLines()
        return segments
    }

    private static func renderImage(_ image: MarkdownImage, baseURL: URL) -> String {
        let alt = escapeHTML(image.alt)
        let caption = alt.isEmpty ? "" : "<figcaption>\(alt)</figcaption>"

        guard let source = imageSource(for: image.destination, baseURL: baseURL) else {
            return """
            <figure>
              <p><em>\(alt.isEmpty ? "Image preview unavailable." : alt)</em></p>
            </figure>
            """
        }

        return """
        <figure>
          <img src="\(escapeHTML(source))" alt="\(alt)">
          \(caption)
        </figure>
        """
    }

    private static func imageSource(for destination: String, baseURL: URL) -> String? {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() {
            if scheme == "file" {
                return url.absoluteString
            }
            if scheme == "data", trimmed.lowercased().hasPrefix("data:image/") {
                return trimmed
            }
            return nil
        }

        return URL(fileURLWithPath: trimmed, relativeTo: baseURL).standardizedFileURL.absoluteString
    }

    private static func taskListStateAndContent(from fragments: [Fragment]) -> (TaskListState?, [Fragment]) {
        guard var first = fragments.first else {
            return (nil, fragments)
        }

        let leadingWhitespace = first.text.prefix { $0 == " " || $0 == "\t" }
        let rest = first.text.dropFirst(leadingWhitespace.count)
        let states: [(String, TaskListState)] = [
            ("[ ] ", .unchecked),
            ("[x] ", .checked),
            ("[X] ", .checked)
        ]

        for (prefix, state) in states where rest.hasPrefix(prefix) {
            let replacement = String(rest.dropFirst(prefix.count))
            first = Fragment(
                text: replacement,
                presentationIntent: first.presentationIntent,
                inlineIntent: first.inlineIntent,
                link: first.link
            )

            var updated = Array(fragments.dropFirst())
            if !first.text.isEmpty {
                updated.insert(first, at: 0)
            }
            return (state, updated)
        }

        return (nil, fragments)
    }

    private static func renderTaskMarker(_ state: TaskListState) -> String {
        let stateClass = state == .checked ? " checked" : ""
        return #"<span class="task-marker"><span class="task-checkbox\#(stateClass)"></span></span>"#
    }

    private static func renderTable(_ fragments: [Fragment]) -> String {
        var table = ParsedTable()

        for fragment in fragments {
            let metadata = BlockMetadata(fragment.presentationIntent)
            guard let rowID = metadata.tableRowID else { continue }
            let column = metadata.tableCellColumn ?? 0
            table.columns = metadata.tableColumns.isEmpty ? table.columns : metadata.tableColumns
            table.append(fragment, rowID: rowID, rowIndex: metadata.tableRowIndex, isHeader: metadata.isTableHeader, column: column)
        }

        guard !table.rows.isEmpty else {
            return ""
        }

        let columnCount = max(table.columns.count, table.rows.flatMap { $0.cells.keys }.max().map { $0 + 1 } ?? 0)
        let headerRows = table.rows.filter(\.isHeader)
        let bodyRows = table.rows.filter { !$0.isHeader }

        var html = "<table>"
        if !headerRows.isEmpty {
            html += "<thead>"
            for row in headerRows {
                html += renderTableRow(row, columnCount: columnCount, columns: table.columns, cellTag: "th")
            }
            html += "</thead>"
        }

        if !bodyRows.isEmpty {
            html += "<tbody>"
            for row in bodyRows {
                html += renderTableRow(row, columnCount: columnCount, columns: table.columns, cellTag: "td")
            }
            html += "</tbody>"
        }

        html += "</table>"
        return html
    }

    private static func renderTableRow(_ row: TableRow, columnCount: Int, columns: [PresentationIntent.TableColumn], cellTag: String) -> String {
        var html = "<tr>"
        for columnIndex in 0..<columnCount {
            let alignment = tableAlignment(for: columns[safe: columnIndex])
            let body = (row.cells[columnIndex] ?? []).map(renderInline).joined()
            html += #"<\#(cellTag) style="text-align: \#(alignment);">\#(body)</\#(cellTag)>"#
        }
        html += "</tr>"
        return html
    }

    private static func tableAlignment(for column: PresentationIntent.TableColumn?) -> String {
        switch column?.alignment {
        case .center:
            return "center"
        case .right:
            return "right"
        default:
            return "left"
        }
    }

    private static func renderCodeBlock(_ text: String, language: String?) -> String {
        let languageBadge = language.flatMap { $0.isEmpty ? nil : #"<div class="code-lang">\#(escapeHTML($0))</div>"# } ?? ""
        return """
        <div class="code-block">
          \(languageBadge)
          <pre><code>\(escapeHTML(text.trimmingCharacters(in: .newlines)))</code></pre>
        </div>
        """
    }

    private static func renderInline(_ fragment: Fragment) -> String {
        var html = escapeHTML(fragment.text).replacingOccurrences(of: "\n", with: "<br>")

        if let inlineIntent = fragment.inlineIntent {
            if inlineIntent.contains(.code) {
                html = "<code>\(html)</code>"
            }
            if inlineIntent.contains(.stronglyEmphasized) {
                html = "<strong>\(html)</strong>"
            }
            if inlineIntent.contains(.emphasized) {
                html = "<em>\(html)</em>"
            }
            if inlineIntent.contains(.strikethrough) {
                html = "<s>\(html)</s>"
            }
        }

        if let link = fragment.link {
            let href = escapeHTML(link.absoluteString)
            html = #"<a href="\#(href)" rel="noreferrer">\#(html)</a>"#
        }

        return html
    }

    private static func escapeHTML(_ value: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(value.count)

        for character in value {
            switch character {
            case "&":
                escaped += "&amp;"
            case "<":
                escaped += "&lt;"
            case ">":
                escaped += "&gt;"
            case "\"":
                escaped += "&quot;"
            case "'":
                escaped += "&#39;"
            default:
                escaped.append(character)
            }
        }

        return escaped
    }
}

private enum MarkdownSegment {
    case markdown(String)
    case image(MarkdownImage)

    var isImage: Bool {
        if case .image = self {
            return true
        }
        return false
    }
}

private struct MarkdownImage {
    let alt: String
    let destination: String

    init?(line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("!["),
              trimmed.hasSuffix(")") else {
            return nil
        }

        let afterOpening = trimmed.dropFirst(2)
        guard let separator = afterOpening.range(of: "](") else {
            return nil
        }

        alt = String(afterOpening[..<separator.lowerBound])

        let destinationAndTitle = afterOpening[separator.upperBound..<trimmed.index(before: trimmed.endIndex)]
        guard let parsedDestination = Self.destination(from: String(destinationAndTitle)) else {
            return nil
        }

        destination = parsedDestination
    }

    private static func destination(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("<"), let closingBracket = trimmed.firstIndex(of: ">") {
            let start = trimmed.index(after: trimmed.startIndex)
            return String(trimmed[start..<closingBracket])
        }

        if let firstPart = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" }).first {
            return String(firstPart)
        }

        return nil
    }
}

private enum TaskListState {
    case checked
    case unchecked
}

private struct Fragment {
    let text: String
    let presentationIntent: PresentationIntent?
    let inlineIntent: InlinePresentationIntent?
    let link: URL?
}

private struct BlockMetadata {
    var headingLevel: Int?
    var codeLanguage: String?
    var isBlockQuote = false
    var isThematicBreak = false
    var listOrdinal: Int?
    var isOrderedList = false
    var isUnorderedList = false
    var indentationLevel = 0
    var tableID: Int?
    var tableColumns: [PresentationIntent.TableColumn] = []
    var tableRowID: Int?
    var tableRowIndex: Int?
    var isTableHeader = false
    var tableCellColumn: Int?

    init(_ intent: PresentationIntent?) {
        guard let intent else { return }

        indentationLevel = intent.indentationLevel

        for component in intent.components {
            switch component.kind {
            case .header(let level):
                headingLevel = level
            case .codeBlock(let languageHint):
                codeLanguage = languageHint ?? ""
            case .blockQuote:
                isBlockQuote = true
            case .thematicBreak:
                isThematicBreak = true
            case .orderedList:
                isOrderedList = true
            case .unorderedList:
                isUnorderedList = true
            case .listItem(let ordinal):
                listOrdinal = ordinal
            case .table(let columns):
                tableID = component.identity
                tableColumns = columns
            case .tableHeaderRow:
                tableRowID = component.identity
                tableRowIndex = 0
                isTableHeader = true
            case .tableRow(let rowIndex):
                tableRowID = component.identity
                tableRowIndex = rowIndex
            case .tableCell(let columnIndex):
                tableCellColumn = columnIndex
            case .paragraph:
                break
            @unknown default:
                break
            }
        }
    }

    var listMarker: String? {
        if isOrderedList, let listOrdinal {
            return "\(listOrdinal)."
        }
        if isUnorderedList {
            return "*"
        }
        return nil
    }
}

private struct ParsedTable {
    var columns: [PresentationIntent.TableColumn] = []
    private(set) var rows: [TableRow] = []

    mutating func append(_ fragment: Fragment, rowID: Int, rowIndex: Int?, isHeader: Bool, column: Int) {
        if let index = rows.firstIndex(where: { $0.id == rowID }) {
            rows[index].cells[column, default: []].append(fragment)
            return
        }

        var row = TableRow(id: rowID, rowIndex: rowIndex ?? rows.count, isHeader: isHeader, cells: [:])
        row.cells[column, default: []].append(fragment)
        rows.append(row)
        rows.sort { lhs, rhs in
            if lhs.isHeader != rhs.isHeader {
                return lhs.isHeader && !rhs.isHeader
            }
            return lhs.rowIndex < rhs.rowIndex
        }
    }
}

private struct TableRow {
    let id: Int
    let rowIndex: Int
    let isHeader: Bool
    var cells: [Int: [Fragment]]
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
