import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSButton {
    public func stateBoolValue(isMixedEqualTrue: Bool) -> ControlProperty<Bool> {
        _controlProperty(startWithProperty: true) { base in
            base.state.boolValue(isMixedEqualTrue: isMixedEqualTrue)
        } setter: { base, newValue in
            base.state = .init(boolValue: newValue)
        }
    }

    public var buttonType: Binder<NSButton.ButtonType> {
        Binder(base) { target, newValue in
            target.setButtonType(newValue)
        }
    }

    public var isCheck: ControlProperty<Bool> {
        _controlProperty(startWithProperty: true) {
            $0.state == .on
        } setter: {
            $0.state = $1 ? .on : .off
        }
    }
}
