#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@available(macOS 10.15, *)
extension NSSharingServicePickerToolbarItem: @retroactive HasDelegate {
    public typealias Delegate = NSSharingServicePickerToolbarItemDelegate
}

@available(macOS 10.15, *)
class RxNSSharingServicePickerToolbarItemDelegateProxy: DelegateProxy<NSSharingServicePickerToolbarItem, NSSharingServicePickerToolbarItemDelegate>, RequiredMethodDelegateProxyType, NSSharingServicePickerToolbarItemDelegate {
    
    public private(set) weak var sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem?
    
    init(sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem) {
        self.sharingServicePickerToolbarItem = sharingServicePickerToolbarItem
        super.init(parentObject: sharingServicePickerToolbarItem, delegateProxy: RxNSSharingServicePickerToolbarItemDelegateProxy.self)
    }
    
    let _requiredMethodsDelegate = ObjectContainer<NSSharingServicePickerToolbarItemDelegate>()
    
    static func registerKnownImplementations() {
        register {
            RxNSSharingServicePickerToolbarItemDelegateProxy(sharingServicePickerToolbarItem: $0)
        }
    }
    
    func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        _requiredMethodsDelegate.object?.items(for: pickerToolbarItem) ?? []
    }
    
}

#endif
