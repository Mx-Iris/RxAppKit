#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

class RxNSToolbarProxy: NSObject, NSToolbarItemValidation {
    private unowned let toolbar: NSToolbar

    init(toolbar: NSToolbar) {
        self.toolbar = toolbar
        super.init()
    }

    let didSelectItem = PublishRelay<(NSToolbarItem, Any?)>()

    @objc func run(_ toolbarItem: NSToolbarItem) {
        didSelectItem.accept((toolbarItem, toolbarItem.representedObject))
    }
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        (item.representedObject as? RxToolbarItemRepresentable)?.shouldEnable ?? true
    }
}
#endif
