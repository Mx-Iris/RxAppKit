import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSScrollView {
    var documentOffset: ControlProperty<CGPoint> {
        let source: Observable<CGPoint> = NotificationCenter.default.rx.notification(NSView.boundsDidChangeNotification, object: base.contentView).map { [weak self = base] _ in
            guard let self = self else { return .zero }
            return self.contentView.bounds.origin
        }.asObservable()
        
        let binding = Binder<CGPoint>(base) { scrollView, documentOffset in
            scrollView.contentView.bounds.origin = documentOffset
        }

        return ControlProperty(values: source, valueSink: binding)
    }

    var willStartLiveMagnify: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.willStartLiveMagnifyNotification, object: base)
    }

    var willStartLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.willStartLiveScrollNotification, object: base)
    }
    
    var didLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didLiveScrollNotification, object: base)
    }
    
    var didEndLiveMagnify: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didEndLiveMagnifyNotification, object: base)
    }

    var didEndLiveScroll: ControlEvent<Void> {
        controlEventForNotification(NSScrollView.didEndLiveScrollNotification, object: base)
    }
}
