import AppKit
import RxSwift

extension NSBrowser: HasDoubleAction {}

public extension Reactive where Base: NSBrowser {
    typealias ClickedIndex = (row: Int, column: Int)

    var delegate: DelegateProxy<NSBrowser, NSBrowserDelegate> {
        RxNSBrowserDelegateProxy.proxy(for: base)
    }
    
    func setDelegate(_ delegate: NSBrowserDelegate) -> Disposable {
        RxNSBrowserDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    func rootNode<BrowserNode: BrowserNodeType, Cell: NSCell, Source: ObservableType>(cellClass: Cell.Type)
        -> (_ source: Source)
        -> (_ configureCell: @escaping (_ node: BrowserNode, _ cell: Cell, _ row: Int, _ column: Int) -> Void)
        -> Disposable where Source.Element == BrowserNode {
        return { source in
            { configureCell in
                let adapter = RxNSBrowserAdapter<BrowserNode, Cell>(configureCell: configureCell)
                return self.rootNode(adapter: adapter)(source)
            }
        }
    }

    func rootNode<Adapter: RxNSBrowserDelegateType & NSBrowserDelegate, Source: ObservableType>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Adapter.Element == Source.Element {
        return { source in
            let adapterSubscription = RxNSBrowserDelegateProxy.proxy(for: base).setRequiredMethodsDelegate(adapter)

            base.layoutSubtreeIfNeeded()

            let subscription = source.asObservable()
                .observe(on: MainScheduler.instance)
                .catch { error in
                    bindingError(error)
                    return Observable.empty()
                }
                // source can never end, otherwise it would release the subscriber, and deallocate the data source
                .concat(Observable.never())
                .take(until: base.rx.deallocated)
                .subscribe { [weak object = base] event in
                    guard let broswer = object else { return }
                    adapter.browser(broswer, observedEvent: event)
                    switch event {
                    case let .error(error):
                        bindingError(error)
                        adapterSubscription.dispose()
                    case .completed:
                        adapterSubscription.dispose()
                    default:
                        break
                    }
                }

            return Disposables.create { [weak object = base] in
                adapterSubscription.dispose()
                subscription.dispose()
                object?.layoutSubtreeIfNeeded()
            }
        }
    }

    var clickedIndex: ControlEvent<ClickedIndex> {
        controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var doubleClicked: ControlEvent<ClickedIndex> {
        controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    var path: ControlProperty<String> {
        controlProperty(getter: {
            $0.path()
        }, setter: {
            $0.setPath($1)
        })
    }

    var selectedIndexPath: ControlEvent<IndexPath?> {
        controlEventForBaseAction { $0.selectionIndexPath }
    }
}
