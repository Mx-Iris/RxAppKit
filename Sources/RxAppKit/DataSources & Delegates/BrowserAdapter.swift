import AppKit
import RxSwift

public protocol NodeType {
    associatedtype Child
    var title: String { get }
    var children: [Child] { get }
    var isLeaf: Bool { get }
    init()
}

public extension NodeType {
    var isLeaf: Bool {
        return children.count == 0
    }
}

open class BrowserAdapter<Node: NodeType, Cell: NSCell>: NSObject, NSBrowserDelegate {
    public internal(set) var rootNode: Node = .init()

    public typealias ConfigureCell = (Node, Cell, Int, Int) -> Void

    public typealias HeaderForItem = (NSBrowser, Node) -> NSViewController?

    public typealias PreviewForLeafItem = (NSBrowser, Node) -> NSViewController?

    open var configureCell: ConfigureCell

    open var headerForItem: HeaderForItem?

    open var previewForLeafItem: PreviewForLeafItem?

    public init(configureCell: @escaping ConfigureCell) {
        self.configureCell = configureCell
    }

    open func rootItem(for browser: NSBrowser) -> Any? {
        return rootNode
    }

    open func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? Node else { return 0 }
        return node.children.count
    }

    open func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? Node else {
            rxFatalError("The root node not exist")
        }

        return node.children[index]
    }

    open func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {
        guard let node = item as? Node else { return nil }
        return node.title
    }

    open func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
        guard let node = item as? Node else { return true }
        return node.isLeaf
    }

    open func browser(_ browser: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        guard let cell = cell as? Cell else { return }
        let indexPath = browser.indexPath(forColumn: column).appending(row)
        guard let node = browser.item(at: indexPath) as? Node else { return }
        configureCell(node, cell, row, column)
    }

    open func browser(_ browser: NSBrowser, headerViewControllerForItem item: Any?) -> NSViewController? {
        guard let node = item as? Node else { return nil }
        return headerForItem?(browser, node)
    }

    open func browser(_ browser: NSBrowser, previewViewControllerForLeafItem item: Any) -> NSViewController? {
        guard let node = item as? Node else { return nil }
        return previewForLeafItem?(browser, node)
    }
}
