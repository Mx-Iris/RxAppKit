import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSProgressIndicator {
    public var isAnimating: Binder<Bool> {
        .init(base) { target, active in
            target.isIndeterminate = true
            target.doubleValue = 0
            if active {
                target.startAnimation(nil)
            } else {
                target.stopAnimation(nil)
            }
        }
    }

    public func progressValue<Value: BinaryFloatingPoint>() -> Binder<Value> {
        .init(base) { target, progressValue in
            target.isIndeterminate = false
            target.doubleValue = Double(progressValue)
        }
    }
}
