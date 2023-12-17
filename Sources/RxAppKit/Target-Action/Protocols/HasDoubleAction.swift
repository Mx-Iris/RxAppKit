#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@objc
protocol HasDoubleAction: HasTargeAction {
    var doubleAction: Selector? { set get }
}

private var rx_double_click: UInt8 = 0

extension Reactive where Base: NSObject, Base: HasDoubleAction {
    var lazyDoubleClickObservable: Observable<Void> {
        base.rx.lazyInstanceObservable(&rx_double_click) { () -> Observable<Void> in
            Observable.create { /* [weak weakControl = self.base] */ (observer: AnyObserver<Void>) in
//                guard let control = weakControl else {
//                    observer.on(.completed)
//                    return Disposables.create()
//                }

//                observer.on(.next(()))

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

#endif
