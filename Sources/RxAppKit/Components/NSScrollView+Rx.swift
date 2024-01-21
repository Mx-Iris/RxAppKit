import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSScrollView {
    public var contentOffset: ControlProperty<CGPoint> {
        let source: Observable<CGPoint> = NotificationCenter.default.rx.notification(NSView.boundsDidChangeNotification, object: base.contentView).map { [weak self = base] _ in
            guard let self else { return .zero }
            return self.contentView.bounds.origin
        }.asObservable()

        let binding = Binder<CGPoint>(base) { scrollView, contentOffset in
            scrollView.contentView.bounds.origin = contentOffset
        }

        return ControlProperty(values: source, valueSink: binding)
    }

    public var willStartLiveMagnify: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.willStartLiveMagnifyNotification, object: base)
    }

    public var willStartLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.willStartLiveScrollNotification, object: base)
    }

    public var didLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didLiveScrollNotification, object: base)
    }

    public var didEndLiveMagnify: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didEndLiveMagnifyNotification, object: base)
    }

    public var didEndLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didEndLiveScrollNotification, object: base)
    }

    public var didScrollToTop: ControlEvent<Void> {
        let source = contentOffset.filter { $0.y <= 0 }.map { _ in }
        return ControlEvent(events: source)
    }

    public var didScrollToBottom: ControlEvent<Void> {
        let source = contentOffset.filter { [weak base] contentOffset in
            guard let scrollView = base, let contentHeight = scrollView.documentView?.bounds.height else { return false }
            let visibleHeight = scrollView.documentVisibleRect.height
            guard contentHeight > 0, visibleHeight > 0 else { return false }
            return contentHeight - visibleHeight <= contentOffset.y
        }
        .map { _ in }
        .asObservable()
        return ControlEvent(events: source)
    }
}
