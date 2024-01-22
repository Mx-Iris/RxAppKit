#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

public class RxNSToolbarAdapter<Item: RxToolbarItemRepresentable>: ToolbarAdapter<Item>, RxNSToolbarDelegateType {
    public typealias Element = [Item]

    public func toolbar(_ toolbar: NSToolbar, observedEvent: Event<[Item]>) {
        Binder(self) { adapter, newItems in
            adapter.setItems(newItems)
            toolbar.reloadData()
        }.on(observedEvent)
    }
}

#endif
