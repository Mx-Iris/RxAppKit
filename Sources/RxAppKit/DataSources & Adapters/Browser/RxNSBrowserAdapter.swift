import AppKit
import RxSwift

open class RxNSBrowserAdapter<BrowserNode: BrowserNodeType, Cell: NSCell>: BrowserAdapter<BrowserNode, Cell>, RxNSBrowserDelegateType {
    public typealias Element = BrowserNode
    
    open func browser(_ browser: NSBrowser, observedEvent: Event<Element>) {
        Binder<Element>(self) { adapter, newNode in
            adapter.rootNode = newNode
            // Reload Data
            browser.reloadColumn(0)
        }.on(observedEvent)
    }
}
