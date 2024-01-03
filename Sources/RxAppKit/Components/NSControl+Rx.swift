import AppKit
import RxSwift

extension NSControl: HasTargeAction {}

public extension Reactive where Base: HasTargeAction {
    var click: ControlEvent<Void> {
        _controlEventForBaseAction { _ in () }
    }
    
    
    func click<Value>(with keyPath: KeyPath<Base, Value>, isStartWithDefaultValue: Bool = false) -> ControlEvent<Value> {
        var source = _controlEventForBaseAction { $0[keyPath: keyPath] }.asObservable()
        if isStartWithDefaultValue {
            source = source.startWith(base[keyPath: keyPath])
        }
        return ControlEvent(events: source)
    }
    
    /// Creates a `ControlProperty` that is triggered by target/action pattern value updates.
    ///
    /// - parameter getter: Property value getter.
    /// - parameter setter: Property value setter.
//    func controlProperty<T>(
//        getter: @escaping (Base) -> T,
//        setter: @escaping (Base, T) -> Void
//    ) -> ControlProperty<T> {
//        MainScheduler.ensureRunningOnMainThread()
//
//        let source = lazyControlObservable
//        .flatMap { [weak base] _ -> Observable<T> in
//            guard let control = base else { return Observable.empty() }
//            return Observable.just(getter(control))
//        }
//
//        let bindingObserver = Binder(base, binding: setter)
//
//        return ControlProperty(values: source, valueSink: bindingObserver)
//    }
}


