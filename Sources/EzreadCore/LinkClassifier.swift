import Foundation

public enum LinkTarget: Equatable {
    case page
    case anchor
    case internalMarkdown(path: String, fragment: String?)
    case external
    case blocked
}

public enum LinkClassifier {
    public static func classify(_ url: URL?) -> LinkTarget {
        guard let url, let scheme = url.scheme?.lowercased() else { return .blocked }

        switch scheme {
        case "http", "https", "mailto":
            return .external
        case "ezread":
            return classifyLocal(url)
        default:
            return .blocked
        }
    }

    private static func classifyLocal(_ url: URL) -> LinkTarget {
        switch url.host {
        case "app":
            guard url.path == "/page.html" else { return .blocked }
            return url.fragment == nil ? .page : .anchor
        case "root":
            let path = String(url.path.drop { $0 == "/" })
            guard RepoScanner.isMarkdown(path) else { return .blocked }
            return .internalMarkdown(path: path, fragment: url.fragment)
        default:
            return .blocked
        }
    }
}
