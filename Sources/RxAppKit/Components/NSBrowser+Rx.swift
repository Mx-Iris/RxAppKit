import AppKit
import RxSwift
import RxCocoa

extension NSBrowser: HasDoubleAction {}

public extension Reactive where Base: NSBrowser {
    typealias ClickedIndex = (row: Int, column: Int)

    func rootNode<Node: NodeType, Cell: NSCell, Source: ObservableType>(cellClass: Cell.Type)
        -> (_ source: Source)
        -> (_ configureCell: @escaping (_ node: Node, _ cell: Cell, _ row: Int, _ column: Int) -> Void)
        -> Disposable where Source.Element == Node {
        return { source in
            { configureCell in
                let adapter = RxNSBrowserAdapter<Node, Cell>(configureCell: configureCell)
                return self.rootNode(adapter: adapter)(source)
            }
        }
    }

    func rootNode<Adapter: RxNSBrowserDelegateType & NSBrowserDelegate, Source: ObservableType>(adapter: Adapter)
        -> (_ source: Source)
        -> Disposable where Adapter.Element == Source.Element {
        return { source in
            source.subscribeProxyDataSource(ofObject: base, dataSource: adapter, retainDataSource: true) { [weak browser = base] (_: RxBrowserDelegateProxy, event) in
                guard let browser = browser else { return }
                adapter.browser(browser, observedEvent: event)
            }
        }
    }

    var clickedIndex: ControlEvent<ClickedIndex> {
        controlEventForBaseAction { ($0.clickedRow, $0.clickedRow) }
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
