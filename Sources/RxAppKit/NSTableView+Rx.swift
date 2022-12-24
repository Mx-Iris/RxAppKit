//
//  NSTableView+Rx.swift
//
//
//  Created by JH on 2022/12/23.
//

import Cocoa
import RxSwift
import RxCocoa

private var rx_double_click: UInt8 = 0

public extension Reactive where Base: NSTableView {
    var doubleClick: ControlEvent<Void> {
        MainScheduler.ensureRunningOnMainThread()
        let source = lazyInstanceObservable(&rx_double_click) { () -> Observable<Void> in
            Observable.create { [weak tableView = self.base] observer in
                MainScheduler.ensureRunningOnMainThread()
                guard let tableView = tableView else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                let observer = DoubleClickTarget<NSTableView>(control: tableView) { _ in
                    observer.on(.next(()))
                }
                return observer
            }
            .take(until: deallocated)
            .share()
        }
        return ControlEvent(events: source)
    }

    var delegate: DelegateProxy<NSTableView, NSTableViewDelegate> {
        RxNSTableViewDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSTableViewDelegate) -> Disposable {
        RxNSTableViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var dataSource: DelegateProxy<NSTableView, NSTableViewDataSource> {
        RxNSTableViewDataSourceProxy.proxy(for: base)
    }

    func items<Sequeuce: Swift.Sequence, Source: ObservableType>(_ source: Source)
        -> (_ viewForRow: @escaping (NSTableView, NSTableColumn?, Int, Sequeuce.Element) -> NSView?)
        -> Disposable where Source.Element == Sequeuce {
        return { viewForRow in
            let adapter = RxNSTableViewAdapter<Sequeuce>(viewForRow: viewForRow)
            return self.items(adapter: adapter)(source)
        }
    }

    func items<Source: ObservableType, Adapter: RxNSTableViewDataSourceType & NSTableViewDataSource & NSTableViewDelegate>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Source.Element == Adapter.Element {
        return { source in
            let delegateSubscription = self.setDelegate(adapter)
            let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak tableView = self.base] (_: RxNSTableViewDataSourceProxy, event) in
                guard let tableView = tableView else { return }
                adapter.tableView(tableView, observedEvent: event)
            }
            return Disposables.create(delegateSubscription, dataSourceSubscription)
        }
    }
}

extension NSTableView: DoubleClickable {}

protocol DoubleClickable: AnyObject {
    var target: AnyObject? { set get }
    var doubleAction: Selector? { set get }
}

private class DoubleClickTarget<Control: DoubleClickable>: RxTarget {
    typealias Callback = (Control) -> Void

    let selector: Selector = #selector(actionHanlder)

    let callback: Callback

    weak var control: Control?

    init(control: Control, callback: @escaping Callback) {
        MainScheduler.ensureRunningOnMainThread()
        self.control = control
        self.callback = callback
        super.init()
        control.target = self
        control.doubleAction = selector
    }

    @objc func actionHanlder() {
        if let control = control {
            callback(control)
        }
    }
}
