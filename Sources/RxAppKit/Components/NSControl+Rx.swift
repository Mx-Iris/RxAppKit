import AppKit
import RxSwift
import RxCocoa


extension NSControl: HasTargeAction {}

public extension Reactive where Base: NSControl {
    var clicked: ControlEvent<Void> {
        controlEventForBaseAction { _ in () }
    }
}
