import Foundation
import RxSwift

@objc
protocol HasTargeAction: AnyObject {
    var target: AnyObject? { set get }
    var action: Selector? { set get }
}

extension HasTargeAction where Self: AnyObject {
    var targetSetterSelector: Selector { #selector(setter: target) }
    var actionSetterSelector: Selector { #selector(setter: action) }
}

@objc
protocol HasTargetRequiredAction: AnyObject {
    var target: AnyObject? { set get }
    var action: Selector { set get }
}

// This should be only used from `MainScheduler`
class BaseTarget: RxTarget {
    typealias Callback = () -> Void

    let selector = #selector(baseActionHandler)

    var callback: Callback?

    init(callback: @escaping Callback) {
        self.callback = callback
        super.init()
    }

    @objc func baseActionHandler() {
        callback?()
    }

    override func dispose() {
        super.dispose()
        callback = nil
    }
}

private var rx_control_observable_key: UInt8 = 0
private var rx_appkit_control_event_key: Void = ()
private var rx_appkit_control_property_key: Void = ()
extension Reactive where Base: NSObject, Base: HasTargeAction {
//    var lazyControlObservable: Observable<Void> {
//        base.rx.lazyInstanceObservable(&rx_control_observable_key) { () -> Observable<Void> in
//            Observable.create { (observer: AnyObserver<Void>) in
//
//                observer.on(.next(()))
//
//                let target = BaseTarget{
//                    observer.on(.next(()))
//                }
//
//                proxy.addForwardTarget(target, action: target.selector, doubleAction: nil)
//
//                return target
//            }
//            .take(until: self.deallocated)
    ////            .share(replay: 1, scope: .whileConnected)
//            .share()
//        }
//    }

    func controlEventForBaseAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_event_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

//                observer.on(.next(()))

                let target = BaseTarget {
                    observer.on(.next(()))
                }

                proxy.addForwardTarget(target, action: target.selector, doubleAction: nil)

                return target
            }
            .take(until: self.deallocated)
//            .share(replay: 1, scope: .whileConnected)
            .share()
        }
        .flatMap { [weak base] _ -> Observable<PropertyType> in
            guard let base = base else { return .empty() }
            return Observable.just(makeEvent(base))
        }

        return ControlEvent(events: source)
    }

    func controlProperty<Value>(forKeyPath keyPath: ReferenceWritableKeyPath<Base, Value>) -> ControlProperty<Value> {
        return base.rx.controlProperty(
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
    func controlProperty<T>(
        getter: @escaping (Base) -> T,
        setter: @escaping (Base, T) -> Void
    ) -> ControlProperty<T> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_property_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

//                observer.on(.next(()))

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

extension Reactive where Base: NSObject, Base: HasTargetRequiredAction {
//    var lazyControlObservable: Observable<Void> {
//        base.rx.lazyInstanceObservable(&rx_control_observable_key) { () -> Observable<Void> in
//            Observable.create { /* [weak weakControl = self.base] */ (observer: AnyObserver<Void>) in
    ////                guard let control = weakControl else {
    ////                    observer.on(.completed)
    ////                    return Disposables.create()
    ////                }
//
//                observer.on(.next(()))
//
//                let target = BaseTarget {
//                    observer.on(.next(()))
//                }
//
//                proxy.addForwardTarget(target, action: target.selector, doubleAction: nil)
//
//                return target
//            }
//            .take(until: self.deallocated)
//            .share(replay: 1, scope: .whileConnected)
//        }
//    }

    func controlEventForBaseAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_event_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

//                observer.on(.next(()))

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
            guard let base = base else { return .empty() }
            return Observable.just(makeEvent(base))
        }

        return ControlEvent(events: source)
    }

    func controlProperty<Value>(forKeyPath keyPath: ReferenceWritableKeyPath<Base, Value>) -> ControlProperty<Value> {
        return base.rx.controlProperty(
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
    func controlProperty<T>(
        getter: @escaping (Base) -> T,
        setter: @escaping (Base, T) -> Void
    ) -> ControlProperty<T> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_property_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

//                observer.on(.next(()))

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
