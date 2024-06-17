#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@available(macOS 10.15, *)
class RxNSSharingServicePickerToolbarItemAdapter: SharingServicePickerToolbarItemAdapter, RxNSSharingServicePickerToolbarItemDelegateType {
    typealias Element = [Any]
    func sharingServicePickerToolbarItem(_ sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem, observedEvent: Event<Element>) {
        Binder(self) { target, newValue in
            target.items = newValue
        }
        .on(observedEvent)
    }
}


#endif
