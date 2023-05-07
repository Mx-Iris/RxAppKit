import AppKit
import RxSwift
import RxCocoa

extension NSTableView: HasDelegate {
    public typealias Delegate = NSTableViewDelegate
}

class RxNSTableViewDelegateProxy: DelegateProxy<NSTableView, NSTableViewDelegate>, DelegateProxyType, NSTableViewDelegate {
    public private(set) weak var tableView: NSTableView?

    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSTableViewDelegateProxy(tableView: $0) }
    }

    private weak var _requiredMethodsDelegate: NSTableViewDelegate?

    func setRequiredMethodsDelegate(_ requiredMethodsDelegate: NSTableViewDelegate) {
        _requiredMethodsDelegate = requiredMethodsDelegate
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        _requiredMethodsDelegate?.tableView?(tableView, viewFor: tableColumn, row: row)
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        _requiredMethodsDelegate?.tableView?(tableView, rowViewForRow: row)
    }
}
