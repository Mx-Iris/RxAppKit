import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSView {
    var firstLayout: Single<Void> {
        base.rx.methodInvoked(#selector(Base.layout))
            .map { _ in }
            .take(1)
            .asSingle()
    }
}
