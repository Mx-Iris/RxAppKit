#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

open class RxNSToolbarAdapter<Item: RxToolbarItemRepresentable>: ToolbarAdapter<Item>, RxNSToolbarDelegateType {
    public typealias Element = [Item]

    open func toolbar(_ toolbar: NSToolbar, observedEvent: Event<[Item]>) {
        Binder(self) { adapter, newItems in
            adapter.setItems(newItems)
            toolbar.reloadData()
        }.on(observedEvent)
    }
}

#endif
