import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSDatePicker {
    var dateValue: ControlProperty<Date> {
        return _controlProperty(forKeyPath: \.dateValue)
    }
}
