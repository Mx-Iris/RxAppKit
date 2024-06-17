#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

@available(macOS 10.15, *)
public protocol RxNSSharingServicePickerToolbarItemDelegateType {
    associatedtype Element

    func sharingServicePickerToolbarItem(_ sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem, observedEvent: Event<Element>)
}

#endif
