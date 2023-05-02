import AppKit
import RxSwift
import RxCocoa

open class RxNSBrowserAdapter<Node: NodeType, Cell: NSCell>: BrowserAdapter<Node, Cell>, RxNSBrowserDelegateType {
    public typealias Element = Node
    open func browser(_ browser: NSBrowser, observedEvent: Event<Element>) {
        Binder<Element>(self) { adapter, newNode in
            adapter.rootNode = newNode
            // Reload Data
            browser.reloadColumn(0)
        }.on(observedEvent)
    }
}
