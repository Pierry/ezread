import AppKit
import WebKit
import ZreadCore

/// Decides every WebView navigation. Anything not recognized is cancelled.
final class LinkRouter: NSObject, WKNavigationDelegate {
    var onInternalLink: ((String, String?) -> Void)?
    var onPageLoaded: (() -> Void)?

    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = action.request.url
        switch LinkClassifier.classify(url) {
        case .page:
            decisionHandler(action.navigationType == .linkActivated ? .cancel : .allow)
        case .anchor:
            decisionHandler(.allow)
        case .internalMarkdown(let path, let fragment):
            decisionHandler(.cancel)
            onInternalLink?(path, fragment)
        case .external:
            decisionHandler(.cancel)
            if action.navigationType == .linkActivated, let url {
                NSWorkspace.shared.open(url)
            }
        case .blocked:
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onPageLoaded?()
    }
}
