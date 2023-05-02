import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSStepper {
    var doubleValue: ControlProperty<Double> {
        return controlProperty(valuePath: \.doubleValue)
    }

    var integerValue: ControlProperty<Int> {
        return controlProperty(valuePath: \.integerValue)
    }
}
