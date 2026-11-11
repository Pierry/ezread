import Foundation
import UniformTypeIdentifiers
import WebKit
import EzreadCore

/// Serves `ezread://app/` from the bundle and images under `ezread://root/` from
/// the open repository. Anything else fails.
final class LocalScheme: NSObject, WKURLSchemeHandler {
    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "svg", "webp", "avif", "bmp", "ico"]

    private let root: URL
    private let webRoot: URL

    init(root: URL) {
        self.root = root
        self.webRoot = Bundle.main.resourceURL!.appendingPathComponent("web", isDirectory: true)
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url, let file = resolve(url), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        let response = URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private func resolve(_ url: URL) -> URL? {
        let path = String(url.path.drop { $0 == "/" })
        switch url.host {
        case "app":
            return PathGuard.resolve(relativePath: path, root: webRoot)
        case "root":
            guard Self.imageExtensions.contains((path as NSString).pathExtension.lowercased()) else { return nil }
            return PathGuard.resolve(relativePath: path, root: root)
        default:
            return nil
        }
    }
}
