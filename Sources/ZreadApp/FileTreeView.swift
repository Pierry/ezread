import AppKit
import ZreadCore

private final class TreeItem {
    let node: FileNode
    let children: [TreeItem]

    init(_ node: FileNode) {
        self.node = node
        self.children = (node.children ?? []).map(TreeItem.init)
    }
}

private final class SubtleRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        Theme.selection.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 1), xRadius: 5, yRadius: 5).fill()
    }
}

final class FileTreeView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private let scrollView = NSScrollView()
    private let outline = NSOutlineView()
    private var items: [TreeItem] = []
    private var isSelectingProgrammatically = false

    var onSelect: ((String) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)

        let column = NSTableColumn(identifier: .init("name"))
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        column.resizingMask = .autoresizingMask
        outline.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        outline.headerView = nil
        outline.style = .plain
        outline.backgroundColor = .clear
        outline.rowHeight = 26
        outline.indentationPerLevel = 12
        outline.focusRingType = .none
        outline.dataSource = self
        outline.delegate = self

        scrollView.documentView = outline
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 44, left: 0, bottom: 12, right: 0)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.frame = bounds
        addSubview(scrollView)

        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    override func updateLayer() {
        layer?.backgroundColor = Theme.background.cgColor
    }

    override var wantsUpdateLayer: Bool { true }

    func update(nodes: [FileNode], selected: String?) {
        items = nodes.map(TreeItem.init)
        outline.reloadData()
        outline.expandItem(nil, expandChildren: true)
        select(relativePath: selected)
    }

    func select(relativePath: String?) {
        guard let relativePath else { return }
        for row in 0..<outline.numberOfRows {
            if let item = outline.item(atRow: row) as? TreeItem, item.node.relativePath == relativePath {
                isSelectingProgrammatically = true
                outline.selectRowIndexes([row], byExtendingSelection: false)
                outline.scrollRowToVisible(row)
                isSelectingProgrammatically = false
                return
            }
        }
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? TreeItem)?.children.count ?? items.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? TreeItem)?.children[index] ?? items[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? TreeItem)?.node.isDirectory ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        SubtleRowView()
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let treeItem = item as? TreeItem else { return nil }
        let label = NSTextField(labelWithString: treeItem.node.name)
        label.font = NSFont(name: "Helvetica Neue", size: 13)
        label.textColor = Theme.text
        label.lineBreakMode = .byTruncatingMiddle
        label.alphaValue = treeItem.node.isDirectory ? 0.6 : 1

        let cell = NSTableCellView()
        cell.textField = label
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let treeItem = item as? TreeItem else { return false }
        if treeItem.node.isDirectory {
            if outlineView.isItemExpanded(treeItem) {
                outlineView.collapseItem(treeItem)
            } else {
                outlineView.expandItem(treeItem)
            }
            return false
        }
        return true
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !isSelectingProgrammatically,
              let item = outline.item(atRow: outline.selectedRow) as? TreeItem else { return }
        onSelect?(item.node.relativePath)
    }
}
