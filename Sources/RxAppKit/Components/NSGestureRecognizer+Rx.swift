import AppKit
import RxSwift
import RxCocoa

extension NSGestureRecognizer: HasTargeAction {}

public extension Reactive where Base: NSGestureRecognizer {
    var event: ControlEvent<Base> {
        controlEventForBaseAction { $0 }
    }
}
