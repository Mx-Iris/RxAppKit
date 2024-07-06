#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

private enum RxHasTargetActionKey {
    static var controlEvent: Void = ()
    static var controlProperty: Void = ()
}

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

    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Property>) -> ControlEvent<Property> where Base: AnyObject {
        _controlEventForBaseAction { $0[keyPath: keyPath] }
    }

    func _controlEventForBaseAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&RxHasTargetActionKey.controlEvent) {  () -> Observable<Void> in
            Observable.create { [weak proxy] (observer: AnyObserver<Void>)  in
                guard let proxy else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                let target = BaseTarget {
                    observer.on(.next(()))
                }

                proxy.addForwardTarget(target, action: target.selector, doubleAction: nil)

                return target
            }
            .take(until: self.deallocated)
            .share()
        }
        .flatMap { [weak base] _ -> Observable<PropertyType> in
            guard let base else { return .empty() }
            return Observable.just(makeEvent(base))
        }

        return ControlEvent(events: source)
    }

    func _controlProperty<Value>(forKeyPath keyPath: ReferenceWritableKeyPath<Base, Value>) -> ControlProperty<Value> {
        return base.rx._controlProperty(
            getter: { control -> Value in
                control[keyPath: keyPath]
            }, setter: { control, value in
                control[keyPath: keyPath] = value
            }
        )
    }

    /// Creates a `ControlProperty` that is triggered by target/action pattern value updates.
    ///
    /// - parameter getter: Property value getter.
    /// - parameter setter: Property value setter.
    func _controlProperty<T>(
        getter: @escaping (Base) -> T,
        setter: @escaping (Base, T) -> Void
    ) -> ControlProperty<T> {
        MainScheduler.ensureRunningOnMainThread()

        var source = base.rx.lazyInstanceObservable(&RxHasTargetActionKey.controlProperty) { () -> Observable<Void> in
            Observable.create { [weak proxy] (observer: AnyObserver<Void>) in
                guard let proxy else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                let target = BaseTarget {
                    observer.on(.next(()))
                }

                proxy.addForwardTarget(target, action: target.selector, doubleAction: nil)

                return target
            }
            .take(until: self.deallocated)
            .share(replay: 1, scope: .whileConnected)
        }
        .flatMap { [weak base] _ -> Observable<T> in
            guard let control = base else { return Observable.empty() }
            return Observable.just(getter(control))
        }

        let bindingObserver = Binder(base, binding: setter)

        return ControlProperty(values: source, valueSink: bindingObserver)
    }
}

#endif
