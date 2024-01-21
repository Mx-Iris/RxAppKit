import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSStepper {
    public var doubleValue: ControlProperty<Double> {
        return _controlProperty(forKeyPath: \.doubleValue)
    }

    public var integerValue: ControlProperty<Int> {
        return _controlProperty(forKeyPath: \.integerValue)
    }
}
