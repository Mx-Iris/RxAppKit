import AppKit
import RxSwift

extension Reactive where Base: HasDoubleAction {
    public var doubleClick: ControlEvent<Void> {
        _controlEventForDoubleAction { _ in () }
    }
}

private enum RxHasDoubleActionKey {
    static var controlEvent: Void = ()
}

extension Reactive where Base: NSObject, Base: HasDoubleAction {
    var lazyDoubleClickObservable: Observable<Void> {
        base.rx.lazyInstanceObservable(&RxHasDoubleActionKey.controlEvent) { () -> Observable<Void> in
            Observable.create { [weak doubleActionProxy] (observer: AnyObserver<Void>) in
                guard let doubleActionProxy else {
                    observer.onCompleted()
                    return Disposables.create {}
                }
                
                let target = DoubleClickTarget {
                    observer.on(.next(()))
                }

                doubleActionProxy.addForwardTarget(target, action: nil, doubleAction: target.selector)

                return target
            }
            .take(until: self.deallocated)
            .share(replay: 1, scope: .whileConnected)
        }
    }

    func _controlEventForDoubleAction<PropertyType>(_ makeEvent: @escaping (Base) -> PropertyType) -> ControlEvent<PropertyType> {
        MainScheduler.ensureRunningOnMainThread()
        let source = lazyDoubleClickObservable
            .flatMap { [weak base] _ -> Observable<PropertyType> in
                guard let base else { return .empty() }
                return Observable.just(makeEvent(base))
            }

        return ControlEvent(events: source)
    }
}
