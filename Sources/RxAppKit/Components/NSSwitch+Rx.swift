import AppKit
import RxSwift
import RxCocoa

@available(macOS 10.15, *)
public extension Reactive where Base: NSSwitch {
    /// Reactive wrapper for `state` property`.
    var state: ControlProperty<NSControl.StateValue> {
        return base.rx.controlProperty(
            getter: { control in
                control.state
            }, setter: { (control: Base, state: NSControl.StateValue) in
                control.state = state
            }
        )
    }
}
