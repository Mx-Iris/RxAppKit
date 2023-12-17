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
}

extension NSControl.StateValue {
    init(boolValue: Bool) {
        self = boolValue ? .on : .off
    }

    func boolValue(isMixedEqualTrue: Bool) -> Bool {
        switch self {
        case .on:
            true
        case .off:
            false
        case .mixed:
            isMixedEqualTrue ? true : false
        default:
            false
        }
    }
}
