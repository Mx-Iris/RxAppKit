//
//  DelegateProxyType.swift
//  General Store
//
//  Created by Yumenosuke Koukata on 2020/05/15.
//  Copyright © 2020 ZYXW. All rights reserved.
//

import RxSwift
import RxCocoa
import Cocoa

extension ObservableType {
	func subscribeProxyDataSource<DelegateProxy: DelegateProxyType>(ofObject object: DelegateProxy.ParentObject, dataSource: DelegateProxy.Delegate, retainDataSource: Bool, binding: @escaping (DelegateProxy, Event<Element>) -> Void)
		-> Disposable where DelegateProxy.ParentObject: NSView, DelegateProxy.Delegate: AnyObject {
			let proxy = DelegateProxy.proxy(for: object)
			let unregisterDelegate = DelegateProxy.installForwardDelegate(dataSource, retainDelegate: retainDataSource, onProxyForObject: object)
			// this is needed to flush any delayed old state (https://github.com/RxSwiftCommunity/RxDataSources/pull/75)
			object.layoutSubtreeIfNeeded()
			
			let subscription = self.asObservable()
                .observe(on: MainScheduler())
                .catch { error in
					bindingError(error)
					return Observable.empty()
			}
				// source can never end, otherwise it would release the subscriber, and deallocate the data source
				.concat(Observable.never())
                .take(until: object.rx.deallocated)
				.subscribe { [weak object] (event: Event<Element>) in
					
					if let object = object {
						assert(proxy === DelegateProxy.currentDelegate(for: object), "Proxy changed from the time it was first set.\nOriginal: \(proxy)\nExisting: \(String(describing: DelegateProxy.currentDelegate(for: object)))")
					}
					
					binding(proxy, event)
					
					switch event {
					case .error(let error):
						bindingError(error)
						unregisterDelegate.dispose()
					case .completed:
						unregisterDelegate.dispose()
					default:
						break
					}
			}
			
			return Disposables.create { [weak object] in
				subscription.dispose()
				object?.layoutSubtreeIfNeeded()
				unregisterDelegate.dispose()
			}
	}
}
