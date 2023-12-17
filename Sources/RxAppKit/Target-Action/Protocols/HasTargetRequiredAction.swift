#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@objc
protocol HasTargetRequiredAction: AnyObject {
    var target: AnyObject? { set get }
    var action: Selector { set get }
}

private var rx_appkit_control_event_key: Void = ()
private var rx_appkit_control_property_key: Void = ()

extension Reactive where Base: NSObject, Base: HasTargetRequiredAction {
    func controlEventForBaseAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_event_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

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

    func controlProperty<Value>(forKeyPath keyPath: ReferenceWritableKeyPath<Base, Value>) -> ControlProperty<Value> {
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

        let source = base.rx.lazyInstanceObservable(&rx_appkit_control_property_key) { () -> Observable<Void> in
            Observable.create { (observer: AnyObserver<Void>) in

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
