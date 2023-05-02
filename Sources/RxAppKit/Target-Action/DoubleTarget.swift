import Foundation
import RxSwift
import RxCocoa

protocol HasDoubleAction: HasTargeAction {
    var doubleAction: Selector? { set get }
}

// This should be only used from `MainScheduler`
final class DoubleClickTarget<Component: HasDoubleAction>: BaseTarget<Component> {
    typealias Callback = (Component) -> Void

    let doubleActionSelector: Selector = #selector(doubleActionHandler)

    var doubleActionCallback: Callback?

    init(_ component: Component, baseAction: @escaping Callback, doubleAction: @escaping Callback) {
        MainScheduler.ensureRunningOnMainThread()
        self.doubleActionCallback = doubleAction
        super.init(component, baseAction: baseAction)
        component.doubleAction = selector
    }

    @objc func doubleActionHandler() {
        if let doubleActionCallback = doubleActionCallback, let component = component {
            doubleActionCallback(component)
        }
    }

    override func dispose() {
        super.dispose()
        component?.doubleAction = nil
        doubleActionCallback = nil
    }
}

private var rx_double_click: UInt8 = 0

extension Reactive where Base: HasDoubleAction {
    var lazyDoubleClickObservable: Observable<Void> {
        base.rx.lazyInstanceObservable(&rx_double_click) { () -> Observable<Void> in
            Observable.create { [weak weakControl = self.base] (observer: AnyObserver<Void>) in
                guard let control = weakControl,
                      let target = control.target as? BaseTarget<Base>,
                      let baseAction = target.baseActionCallback
                else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                observer.on(.next(()))

                let disposable = DoubleClickTarget(control, baseAction: baseAction) { _ in
                    observer.on(.next(()))
                }

                return disposable
            }
            .take(until: self.deallocated)
            .share(replay: 1, scope: .whileConnected)
        }
    }

    func controlEventForDoubleAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()
        let source = lazyDoubleClickObservable
            .flatMap { [weak base] _ -> Observable<PropertyType> in
                guard let base = base else { return .empty() }
                return Observable.just(makeEvent(base))
            }

        return ControlEvent(events: source)
    }
}
