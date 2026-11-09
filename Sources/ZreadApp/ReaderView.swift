import AppKit
import WebKit
import ZreadCore

private final class ScrollRelay: NSObject, WKScriptMessageHandler {
    var onLine: ((Int) -> Void)?

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        if let line = message.body as? Int { onLine?(line) }
    }
}

final class ReaderView: NSView {
    let web: WKWebView
    private let router = LinkRouter()
    private let scrollRelay = ScrollRelay()
    private var isReady = false
    private var pending: [() -> Void] = []

    /// Called with the top visible source line after the reader stops scrolling.
    var onTopLineChanged: ((Int) -> Void)? {
        didSet { scrollRelay.onLine = onTopLineChanged }
    }

    var onInternalLink: ((String, String?) -> Void)? {
        didSet { router.onInternalLink = onInternalLink }
    }

    init(root: URL) {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(LocalScheme(root: root), forURLScheme: "zread")
        configuration.userContentController.add(scrollRelay, name: "zreadScroll")
        web = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: .zero)

        web.autoresizingMask = [.width, .height]
        web.frame = bounds
        web.navigationDelegate = router
        web.underPageBackgroundColor = Theme.background
        web.alphaValue = 0
        addSubview(web)

        router.onPageLoaded = { [weak self] in
            guard let self else { return }
            self.isReady = true
            self.pending.forEach { $0() }
            self.pending.removeAll()
        }
        web.load(URLRequest(url: URL(string: "zread://app/page.html")!))

        applySettings()
        NotificationCenter.default.addObserver(self, selector: #selector(applySettings), name: .readerSettingsChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func applySettings() {
        run("zread.applySettings(\(SettingsStore.current.javaScriptArgument())); true")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    func show(html: String, highlight: Bool, completion: (() -> Void)? = nil) {
        guard let argument = Self.jsonString(html) else { return }
        run("zread.setContent(\(argument), \(highlight)); true") { [weak self] _ in
            self?.web.alphaValue = 1
            completion?()
        }
    }

    func showAttentionLoading() {
        run("zread.showAttentionLoading(); true")
    }

    func showAttention(_ brief: AttentionBrief) {
        guard let data = try? JSONEncoder().encode(brief) else { return }
        run("zread.showAttention(\(String(decoding: data, as: UTF8.self))); true")
    }

    func showAttentionError(_ message: String) {
        guard let argument = Self.jsonString(message) else { return }
        run("zread.showAttentionError(\(argument)); true")
    }

    func clearAttention() {
        run("zread.clearAttention(); true")
    }

    func scrollToTop() {
        run("zread.scrollToTop(); true")
    }

    func topVisibleLine(_ completion: @escaping (Int) -> Void) {
        run("zread.topVisibleLine()") { result in
            completion((result as? Int) ?? 1)
        }
    }

    func scrollTo(line: Int) {
        run("zread.scrollToLine(\(line)); true")
    }

    func scrollTo(anchor: String) {
        guard let argument = Self.jsonString(anchor) else { return }
        run("zread.scrollToAnchor(\(argument)); true")
    }

    private func run(_ script: String, completion: ((Any?) -> Void)? = nil) {
        let work = { [weak self] in
            self?.web.evaluateJavaScript(script) { result, _ in completion?(result) }
            return
        }
        if isReady { work() } else { pending.append(work) }
    }

    private static func jsonString(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
