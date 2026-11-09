import Foundation
import cmark_gfm
import cmark_gfm_extensions

public struct RenderedDocument: Equatable {
    public let html: String
    /// True when at least one fenced code block names a language.
    public let hasCode: Bool
}

public enum MarkdownRenderer {
    public static let rootURLPrefix = "zread://root/"

    /// Converts Markdown to an HTML fragment. Raw HTML is dropped because the
    /// unsafe option is not set. `documentDirectory` is the document's folder
    /// relative to the repository root, and is used to rewrite relative links.
    public static func render(markdown: String, documentDirectory: String = "") -> RenderedDocument {
        cmark_gfm_core_extensions_ensure_registered()
        let options = CMARK_OPT_SOURCEPOS | CMARK_OPT_VALIDATE_UTF8

        guard let parser = cmark_parser_new(options) else {
            return RenderedDocument(html: "", hasCode: false)
        }
        defer { cmark_parser_free(parser) }

        for name in ["table", "tasklist", "strikethrough", "autolink"] {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        markdown.withCString { cmark_parser_feed(parser, $0, markdown.utf8.count) }
        guard let root = cmark_parser_finish(parser) else {
            return RenderedDocument(html: "", hasCode: false)
        }
        defer { cmark_node_free(root) }

        let hasCode = rewriteAndInspect(root: root, documentDirectory: documentDirectory)

        guard let rendered = cmark_render_html(root, options, cmark_parser_get_syntax_extensions(parser)) else {
            return RenderedDocument(html: "", hasCode: hasCode)
        }
        defer { free(rendered) }
        return RenderedDocument(html: String(cString: rendered), hasCode: hasCode)
    }

    private static func rewriteAndInspect(root: UnsafeMutablePointer<cmark_node>, documentDirectory: String) -> Bool {
        guard let iterator = cmark_iter_new(root) else { return false }
        defer { cmark_iter_free(iterator) }

        var hasCode = false
        while true {
            let event = cmark_iter_next(iterator)
            if event == CMARK_EVENT_DONE { break }
            guard event == CMARK_EVENT_ENTER, let node = cmark_iter_get_node(iterator) else { continue }

            let type = cmark_node_get_type(node)
            if type == CMARK_NODE_CODE_BLOCK {
                if let info = cmark_node_get_fence_info(node), info.pointee != 0 {
                    hasCode = true
                }
            } else if type == CMARK_NODE_IMAGE || type == CMARK_NODE_LINK {
                if let raw = cmark_node_get_url(node) {
                    let original = String(cString: raw)
                    let rewritten = rewrite(url: original, documentDirectory: documentDirectory)
                    if rewritten != original {
                        cmark_node_set_url(node, rewritten)
                    }
                }
            }
        }
        return hasCode
    }

    static func rewrite(url: String, documentDirectory: String) -> String {
        if url.isEmpty || url.hasPrefix("#") || url.hasPrefix("//") || hasScheme(url) {
            return url
        }
        if url.hasPrefix("/") {
            return rootURLPrefix + url.dropFirst()
        }
        guard !documentDirectory.isEmpty else { return rootURLPrefix + url }
        let encoded = documentDirectory.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? documentDirectory
        return rootURLPrefix + encoded + "/" + url
    }

    private static func hasScheme(_ url: String) -> Bool {
        for (index, character) in url.enumerated() {
            if character == ":" { return index > 0 }
            let valid = character.isASCII && (character.isLetter || (index > 0 && (character.isNumber || "+-.".contains(character))))
            if !valid { return false }
        }
        return false
    }
}
