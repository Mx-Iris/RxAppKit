import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSTabViewController {
    public var items: Binder<[NSTabViewItem]> {
        .init(base) { target, tabViewItems in
            target.tabViewItems.forEach(target.removeTabViewItem(_:))
            tabViewItems.forEach(target.addTabViewItem(_:))
        }
    }
}
