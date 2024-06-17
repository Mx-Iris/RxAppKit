#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@available(macOS 10.15, *)
extension NSSharingServicePickerToolbarItem: HasDelegate {
    public typealias Delegate = NSSharingServicePickerToolbarItemDelegate
}

@available(macOS 10.15, *)
class RxNSSharingServicePickerToolbarItemDelegateProxy: DelegateProxy<NSSharingServicePickerToolbarItem, NSSharingServicePickerToolbarItemDelegate>, DelegateProxyType, NSSharingServicePickerToolbarItemDelegate {
    
    public private(set) weak var sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem?
    
    init(sharingServicePickerToolbarItem: NSSharingServicePickerToolbarItem) {
        self.sharingServicePickerToolbarItem = sharingServicePickerToolbarItem
        super.init(parentObject: sharingServicePickerToolbarItem, delegateProxy: RxNSSharingServicePickerToolbarItemDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register {
            RxNSSharingServicePickerToolbarItemDelegateProxy(sharingServicePickerToolbarItem: $0)
        }
    }
    
    func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        []
    }
    
}

#endif
