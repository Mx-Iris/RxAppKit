#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension NSToolbar: HasDelegate {
    public typealias Delegate = NSToolbarDelegate
}

class RxNSToolbarDelegateProxy: DelegateProxy<NSToolbar, NSToolbarDelegate>, RequiredMethodDelegateProxyType, NSToolbarDelegate {
    public private(set) weak var toolbar: NSToolbar?
    
    public init(toolbar: ParentObject) {
        self.toolbar = toolbar
        super.init(parentObject: toolbar, delegateProxy: RxNSToolbarDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        register { RxNSToolbarDelegateProxy(toolbar: $0) }
    }
    
    let _requiredMethodsDelegate: ObjectContainer<NSToolbarDelegate> = .init()
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        _requiredMethodsDelegate.object?.toolbar?(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate.object?.toolbarDefaultItemIdentifiers?(toolbar) ?? []
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate.object?.toolbarAllowedItemIdentifiers?(toolbar) ?? []
    }
    
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        _requiredMethodsDelegate.object?.toolbarSelectableItemIdentifiers?(toolbar) ?? []
    }
    
}


#endif
