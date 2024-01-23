#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

protocol RequiredMethodDelegateProxyType: DelegateProxyType where Delegate: AnyObject {
    
    var _requiredMethodsDelegate: ObjectContainer<Delegate> { get }
    
    func setRequiredMethodsDelegate(_ requiredMethodsDelegate: Delegate?, retainDelegate: Bool)
}

extension RequiredMethodDelegateProxyType {
    func setRequiredMethodsDelegate(_ requiredMethodsDelegate: Delegate?, retainDelegate: Bool) {
        guard let requiredMethodsDelegate else {
            _requiredMethodsDelegate.setObject(nil)
            return
        }
        if retainDelegate {
            _requiredMethodsDelegate.setStrongObject(requiredMethodsDelegate)
        } else {
            _requiredMethodsDelegate.setWeakObject(requiredMethodsDelegate)
        }
    }
}

#endif
