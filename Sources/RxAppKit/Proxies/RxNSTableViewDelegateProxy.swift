import AppKit
import RxSwift
import RxCocoa

extension NSTableView: HasDelegate {
    public typealias Delegate = NSTableViewDelegate
}

class RxNSTableViewDelegateProxy: DelegateProxy<NSTableView, NSTableViewDelegate>, RequiredMethodDelegateProxyType, NSTableViewDelegate {
    public private(set) weak var tableView: NSTableView?

    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSTableViewDelegateProxy(tableView: $0) }
    }

    let _requiredMethodsDelegate: ObjectContainer<NSTableViewDelegate> = .init()

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        _requiredMethodsDelegate.object?.tableView?(tableView, viewFor: tableColumn, row: row)
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        _requiredMethodsDelegate.object?.tableView?(tableView, rowViewForRow: row)
    }
}
