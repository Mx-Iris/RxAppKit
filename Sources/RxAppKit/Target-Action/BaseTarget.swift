import Foundation
import RxSwift
import RxCocoa

protocol HasTargeAction: NSObject {
    var target: AnyObject? { set get }
    var action: Selector? { set get }
}

// This should be only used from `MainScheduler`
class BaseTarget<Component: HasTargeAction>: RxTarget {
    typealias Callback = (Component) -> Void

    let selector = #selector(baseActionHandler)

    weak var component: Component?
    
    var baseActionCallback: Callback?

    init(_ component: Component, baseAction: @escaping Callback) {
        self.component = component
        self.baseActionCallback = baseAction

        super.init()

        component.target = self
        component.action = selector

        let method = self.method(for: selector)
        if method == nil {
            fatalError("Can't find method")
        }
    }

    @objc func baseActionHandler() {
        if let callback = baseActionCallback, let component = component {
            callback(component)
        }
    }

    override func dispose() {
        super.dispose()
        component?.target = nil
        component?.action = nil
        baseActionCallback = nil
    }
}

private var rx_control_observable_key: UInt8 = 0

extension Reactive where Base: HasTargeAction {
    var lazyControlObservable: Observable<Void> {
        base.rx.lazyInstanceObservable(&rx_control_observable_key) { () -> Observable<Void> in
            Observable.create { [weak weakControl = self.base] (observer: AnyObserver<Void>) in
                guard let control = weakControl else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                observer.on(.next(()))

                let disposable = BaseTarget(control) { _ in
                    observer.on(.next(()))
                }

                return disposable
            }
            .take(until: self.deallocated)
            .share(replay: 1, scope: .whileConnected)
        }
    }

    func controlEventForBaseAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()

        let source = lazyControlObservable
            .flatMap { [weak base] _ -> Observable<PropertyType> in
                guard let base = base else { return .empty() }
                return Observable.just(makeEvent(base))
            }

        return ControlEvent(events: source)
    }
    
    func controlProperty<Value>(valuePath: ReferenceWritableKeyPath<Base, Value>) -> ControlProperty<Value> {
        return base.rx.controlProperty(
            getter: { control -> Value in
                control[keyPath: valuePath]
            }, setter: { control, value in
                control[keyPath: valuePath] = value
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

        let source = lazyControlObservable
        .flatMap { [weak base] _ -> Observable<T> in
            guard let control = base else { return Observable.empty() }
            return Observable.just(getter(control))
        }

        let bindingObserver = Binder(base, binding: setter)

        return ControlProperty(values: source, valueSink: bindingObserver)
    }
}
