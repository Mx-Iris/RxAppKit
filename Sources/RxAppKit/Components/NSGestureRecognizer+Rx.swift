import AppKit
import RxSwift
import RxCocoa

extension NSGestureRecognizer: HasTargeAction {}

extension Reactive where Base: NSGestureRecognizer {
    public var event: ControlEvent<Base> {
        _controlEventForBaseAction { $0 }
    }
}
