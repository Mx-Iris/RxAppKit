import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSDatePicker {
    public var dateValue: ControlProperty<Date> {
        return _controlProperty(forKeyPath: \.dateValue)
    }
}
