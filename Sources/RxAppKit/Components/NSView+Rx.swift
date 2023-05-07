import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSView {
    var didFirstLayout: ControlEvent<Void> {
        let source = base.rx.methodInvoked(#selector(Base.layout))
            .map { _ in }
            .take(1)
        return ControlEvent(events: source)
    }

    var didUpdateTrackingAreas: ControlEvent<Void> {
        controlEventForNotification(Base.didUpdateTrackingAreasNotification, object: base)
    }
}
