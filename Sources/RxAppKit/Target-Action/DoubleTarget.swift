import Foundation
import RxSwift

@objc
protocol HasDoubleAction: HasTargeAction {
    var doubleAction: Selector? { set get }
}

// This should be only used from `MainScheduler`
final class DoubleClickTarget: RxTarget {
    typealias Callback = () -> Void

    let selector: Selector = #selector(doubleActionHandler)

    var callback: Callback?

    init(callback: @escaping Callback) {
        MainScheduler.ensureRunningOnMainThread()
        self.callback = callback
    }

    @objc func doubleActionHandler() {
        callback?()
    }

    override func dispose() {
        super.dispose()
        callback = nil
    }
}

private var rx_double_click: UInt8 = 0

extension Reactive where Base: NSObject, Base: HasDoubleAction {
    var lazyDoubleClickObservable: Observable<Void> {
        base.rx.lazyInstanceObservable(&rx_double_click) { () -> Observable<Void> in
            Observable.create { /*[weak weakControl = self.base]*/ (observer: AnyObserver<Void>) in
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
