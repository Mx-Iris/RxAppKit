#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension NSSharingServicePicker: @retroactive HasDelegate {
    public typealias Delegate = NSSharingServicePickerDelegate
}

class RxNSSharingServicePickerDelegateProxy: DelegateProxy<NSSharingServicePicker, NSSharingServicePickerDelegate>, DelegateProxyType, NSSharingServicePickerDelegate {
    
    public private(set) weak var sharingServicePicker: NSSharingServicePicker?
    
    init(sharingServicePicker: NSSharingServicePicker) {
        self.sharingServicePicker = sharingServicePicker
        super.init(parentObject: sharingServicePicker, delegateProxy: RxNSSharingServicePickerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register {
            RxNSSharingServicePickerDelegateProxy(sharingServicePicker: $0)
        }
    }
    
}


#endif
