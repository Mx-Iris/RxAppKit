import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSTabViewController {
    var items: Binder<[NSTabViewItem]> {
        .init(base) { target, tabViewItems in
            target.tabViewItems.forEach(target.removeTabViewItem(_:))
            tabViewItems.forEach(target.addTabViewItem(_:))
        }
    }
}
