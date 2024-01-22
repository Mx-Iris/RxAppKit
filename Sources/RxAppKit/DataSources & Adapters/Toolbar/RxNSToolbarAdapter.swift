#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

class RxNSToolbarAdapter<Item: RxToolbarItemRepresentable>: ToolbarAdapter<Item>, RxNSToolbarDelegateType {
    
    typealias Element = [Item]
    
    
    func toolbar(_ toolbar: NSToolbar, observedEvent: Event<[Item]>) {
        Binder(self) { adapter, newItems in
            adapter.setItems(newItems)
            toolbar.reloadData()
        }.on(observedEvent)
        
    }
    
}

#endif
