import AppKit
import RxSwift

extension NSBrowser: HasDoubleAction {}

extension Reactive where Base: NSBrowser {
    public typealias ClickedIndex = (row: Int, column: Int)

    public var delegate: DelegateProxy<NSBrowser, NSBrowserDelegate> {
        RxNSBrowserDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSBrowserDelegate) -> Disposable {
        RxNSBrowserDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public func rootNode<BrowserNode: BrowserNodeType, Cell: NSCell, Source: ObservableType>(cellClass: Cell.Type)
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

    public func rootNode<Adapter: RxNSBrowserDelegateType & NSBrowserDelegate, Source: ObservableType>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Adapter.Element == Source.Element {
        return { source in
            let adapterSubscription = source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak browser = base] (_: RxNSBrowserDelegateProxy, event) in
                guard let browser else { return }
                adapter.browser(browser, observedEvent: event)
            }


            return Disposables.create {
                adapterSubscription.dispose()
            }
        }
    }

    public var clickedIndex: ControlEvent<ClickedIndex> {
        _controlEventForBaseAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public var doubleClicked: ControlEvent<ClickedIndex> {
        _controlEventForDoubleAction { ($0.clickedRow, $0.clickedColumn) }
    }

    public var path: ControlProperty<String> {
        controlProperty(getter: {
            $0.path()
        }, setter: {
            $0.setPath($1)
        })
    }

    public var selectedIndexPath: ControlEvent<IndexPath?> {
        _controlEventForBaseAction { $0.selectionIndexPath }
    }
}
