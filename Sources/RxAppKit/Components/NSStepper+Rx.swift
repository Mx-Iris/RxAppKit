import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSStepper {
    var doubleValue: ControlProperty<Double> {
        return _controlProperty(forKeyPath: \.doubleValue)
    }

    var integerValue: ControlProperty<Int> {
        return _controlProperty(forKeyPath: \.integerValue)
    }
}
