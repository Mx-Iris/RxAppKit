import Cocoa
import RxCocoa
import RxSwift

class RxNSTableViewArrayDataSource<T>: NSObject, NSTableViewDataSource {
    var items: [T] = []
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }
}

class RxNSTableViewSequenceDataSource<Sequence: Swift.Sequence>
    : RxNSTableViewArrayDataSource<Sequence.Element>
    , RxNSTableViewDataSourceType {
    typealias Element = Sequence

    func tableView(_ tableView: NSTableView, observedEvent: Event<Sequence>) {
        Binder(self) { dataSource, items in
            dataSource.items = items
            tableView.reloadData()
        }.on(observedEvent.map(Array.init))
    }
}

final class RxNSTableViewAdapter<Sequence: Swift.Sequence>: RxNSTableViewSequenceDataSource<Sequence>, NSTableViewDelegate {
    typealias ViewForRow = (NSTableView, NSTableColumn?, Int, Sequence.Element) -> NSView?

    private let viewForRow: ViewForRow

    init(viewForRow: @escaping ViewForRow) {
        self.viewForRow = viewForRow
        super.init()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        viewForRow(tableView, tableColumn, row, items[row])
    }
}
