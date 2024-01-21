import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSplitView {
    public var willResizeSubviews: ControlEvent<Void> {
        controlEventForNotification(Base.willResizeSubviewsNotification, object: base)
    }

    public var didResizeSubviews: ControlEvent<Void> {
        controlEventForNotification(Base.didResizeSubviewsNotification, object: base)
    }
}
