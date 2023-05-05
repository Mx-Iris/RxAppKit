import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSStepper {
    var doubleValue: ControlProperty<Double> {
        return controlProperty(forKeyPath: \.doubleValue)
    }

    var integerValue: ControlProperty<Int> {
        return controlProperty(forKeyPath: \.integerValue)
    }
}
