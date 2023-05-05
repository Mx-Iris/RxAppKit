import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSView {
    var firstLayout: Signal<Void> {
        base.rx.methodInvoked(#selector(Base.layout))
            .map { _ in }
            .take(1)
            .asSignal(onErrorJustReturn: ())
    }
    
    var didUpdateTrackingAreas: ControlEvent<Void> {
        controlEventForNotification(Base.didUpdateTrackingAreasNotification, object: base)
    }
}
