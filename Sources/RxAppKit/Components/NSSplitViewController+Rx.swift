#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSplitViewController {
    public var toggleSidebar: Binder<Any?> {
        Binder(base) { target, sender in
            target.toggleSidebar(sender)
        }
    }
    public var toggleSidebarWithoutSender: Binder<Void> {
        Binder(base) { target, _ in
            target.toggleSidebar(nil)
        }
    }
    
    @available(macOS 14.0, *)
    public var toggleInspector: Binder<Any?> {
        Binder(base) { target, sender in
            target.toggleInspector(sender)
        }
    }
}

#endif
