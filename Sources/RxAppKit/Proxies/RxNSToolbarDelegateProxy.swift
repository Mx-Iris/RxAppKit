#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension NSToolbar: HasDelegate {
    public typealias Delegate = NSToolbarDelegate
}

class RxNSToolbarDelegateProxy: DelegateProxy<NSToolbar, NSToolbarDelegate>, DelegateProxyType, NSToolbarDelegate {
    public private(set) weak var toolbar: NSToolbar?
    
    public init(toolbar: ParentObject) {
        self.toolbar = toolbar
        super.init(parentObject: toolbar, delegateProxy: RxNSToolbarDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        register { RxNSToolbarDelegateProxy(toolbar: $0) }
    }
    
    private weak var _requiredMethodsDelegate: NSToolbarDelegate?
    
    func setRequiredMethodsDelegate(_ requiredMethodsDelegate: NSToolbarDelegate) -> Disposable {
        _requiredMethodsDelegate = requiredMethodsDelegate
        return Disposables.create { [weak self] in
            guard let self = self else { return }
            _requiredMethodsDelegate = nil
        }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        _requiredMethodsDelegate?.toolbar?(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate?.toolbarDefaultItemIdentifiers?(toolbar) ?? []
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate?.toolbarAllowedItemIdentifiers?(toolbar) ?? []
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate?.toolbarSelectableItemIdentifiers?(toolbar) ?? []
    }
    
}


#endif
