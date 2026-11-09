import AppKit

final class SourceEditor: NSView, NSTextViewDelegate {
    private let scrollView = NSTextView.scrollableTextView()
    private var textView: NSTextView { scrollView.documentView as! NSTextView }

    var onChange: (() -> Void)?

    var string: String {
        get { textView.string }
        set {
            textView.string = newValue
            textView.undoManager?.removeAllActions()
        }
    }

    var editorView: NSView { textView }

    override init(frame: NSRect) {
        super.init(frame: frame)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = bounds
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        addSubview(scrollView)

        let view = textView
        view.delegate = self
        view.isRichText = false
        view.importsGraphics = false
        view.allowsUndo = true
        view.font = NSFont(name: "Menlo", size: 14)
        view.backgroundColor = Theme.background
        view.textColor = Theme.text
        view.insertionPointColor = Theme.text
        view.textContainerInset = NSSize(width: 32, height: 56)
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticTextReplacementEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isAutomaticLinkDetectionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    func textDidChange(_ notification: Notification) {
        onChange?()
    }

    /// 1-based line number of the first line visible at the top.
    func topVisibleLine() -> Int {
        guard let layout = textView.layoutManager, let container = textView.textContainer else { return 1 }
        // The container inset keeps the first visible line below the title bar.
        let point = NSPoint(x: 0, y: max(0, scrollView.contentView.bounds.origin.y))
        let glyph = layout.glyphIndex(for: point, in: container)
        let character = layout.characterIndexForGlyph(at: glyph)
        let prefix = (textView.string as NSString).substring(to: min(character, (textView.string as NSString).length))
        return prefix.reduce(into: 1) { count, char in
            if char.isNewline { count += 1 }
        }
    }

    func scrollTo(line: Int) {
        guard let layout = textView.layoutManager, let container = textView.textContainer else { return }
        let text = textView.string as NSString
        var location = 0
        var current = 1
        while current < line && location < text.length {
            location = NSMaxRange(text.lineRange(for: NSRange(location: location, length: 0)))
            current += 1
        }
        guard text.length > 0 else { return }
        layout.ensureLayout(for: container)
        let glyph = layout.glyphIndexForCharacter(at: min(location, text.length - 1))
        let rect = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: max(0, rect.minY)))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}
