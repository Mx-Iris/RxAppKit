import AppKit
import RxSwift
import RxCocoa

extension RequiredMethodDelegateProxyType {
    static func installRequiredMethodDelegate(_ requiredMethodDelegate: Delegate, retainDelegate: Bool, onProxyForObject object: ParentObject) -> Disposable {
        let proxy = self.proxy(for: object)
        proxy.setRequiredMethodsDelegate(requiredMethodDelegate, retainDelegate: retainDelegate)
        return Disposables.create {
            MainScheduler.ensureRunningOnMainThread()
            proxy.setRequiredMethodsDelegate(nil, retainDelegate: retainDelegate)
        }
    }
}


extension ObservableType {
    func subscribeProxyDataSource<DelegateProxy: DelegateProxyType>(
        ofObject object: DelegateProxy.ParentObject,
        dataSource: DelegateProxy.Delegate,
        retainDataSource: Bool,
        binding: @escaping (DelegateProxy, Event<Element>) -> Void
    ) -> Disposable where DelegateProxy.ParentObject: NSObject, DelegateProxy.Delegate: AnyObject {
        let proxy = DelegateProxy.proxy(for: object)

        let setDelegateSubscription = DelegateProxy.installForwardDelegate(dataSource, retainDelegate: retainDataSource, onProxyForObject: object)

        return _subscribeProxyDataSource(ofObject: object, proxy: proxy, setDelegateSubscription: setDelegateSubscription, binding: binding)
    }

    func subscribeProxyDataSource<DelegateProxy: RequiredMethodDelegateProxyType>(
        ofObject object: DelegateProxy.ParentObject,
        dataSource: DelegateProxy.Delegate,
        retainDataSource: Bool,
        binding: @escaping (DelegateProxy, Event<Element>) -> Void
    ) -> Disposable where DelegateProxy.ParentObject: NSObject, DelegateProxy.Delegate: AnyObject {
        let proxy = DelegateProxy.proxy(for: object)

        let setDelegateSubscription = DelegateProxy.installRequiredMethodDelegate(dataSource, retainDelegate: retainDataSource, onProxyForObject: object)

        return _subscribeProxyDataSource(ofObject: object, proxy: proxy, setDelegateSubscription: setDelegateSubscription, binding: binding)
    }

    func _subscribeProxyDataSource<DelegateProxy: DelegateProxyType>(
        ofObject object: DelegateProxy.ParentObject,
        proxy: DelegateProxy,
        setDelegateSubscription: Disposable,
        binding: @escaping (DelegateProxy, Event<Element>) -> Void
    ) -> Disposable where DelegateProxy.ParentObject: NSObject, DelegateProxy.Delegate: AnyObject {
        // this is needed to flush any delayed old state (https://github.com/RxSwiftCommunity/RxDataSources/pull/75)
        if let view = object as? NSView {
            view.layoutSubtreeIfNeeded()
        }

        let subscription = asObservable()
            .observe(on: MainScheduler())
            .catch { error in
                bindingError(error)
                return Observable.empty()
            }
            // source can never end, otherwise it would release the subscriber, and deallocate the data source
            .concat(Observable.never())
            .take(until: object.rx.deallocated)
            .subscribe { [weak object] (event: Event<Element>) in

                if let object {
                    assert(proxy === DelegateProxy.currentDelegate(for: object), "Proxy changed from the time it was first set.\nOriginal: \(proxy)\nExisting: \(String(describing: DelegateProxy.currentDelegate(for: object)))")
                }

                binding(proxy, event)

                switch event {
                case let .error(error):
                    bindingError(error)
                    setDelegateSubscription.dispose()
                case .completed:
                    setDelegateSubscription.dispose()
                default:
                    break
                }
            }

        return Disposables.create { [weak object] in
            subscription.dispose()
            setDelegateSubscription.dispose()
            if let view = object as? NSView {
                view.layoutSubtreeIfNeeded()
            }
        }
    }
}
