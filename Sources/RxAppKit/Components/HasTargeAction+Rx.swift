#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

extension Reactive where Base: HasTargeAction {
    public var click: ControlEvent<Void> {
        _controlEventForBaseAction { _ in () }
    }

    public func click<Value>(with keyPath: KeyPath<Base, Value>, isStartWithDefaultValue: Bool = false) -> ControlEvent<Value> {
        var source = _controlEventForBaseAction { $0[keyPath: keyPath] }.asObservable()
        if isStartWithDefaultValue {
            source = source.startWith(base[keyPath: keyPath])
        }
        return ControlEvent(events: source)
    }

    public var clickWithSelf: ControlEvent<Base> {
        _controlEventForBaseAction { $0 }
    }
    
    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Property>) -> ControlProperty<Property> where Base: AnyObject {
        _controlProperty(forKeyPath: keyPath)
    }
}

extension Reactive where Base: HasDoubleAction {
    public var doubleClick: ControlEvent<Void> {
        _controlEventForDoubleAction { _ in () }
    }
}

#endif
