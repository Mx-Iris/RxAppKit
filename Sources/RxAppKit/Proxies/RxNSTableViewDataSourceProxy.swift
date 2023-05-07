import AppKit
import RxSwift
import RxCocoa

extension NSTableView: HasDataSource {
    public typealias DataSource = NSTableViewDataSource
}

private let nsTableViewDataSourceNotSet = NSTableViewDataSourceNotSet()

private final class NSTableViewDataSourceNotSet: NSObject, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        0
    }
}

class RxNSTableViewDataSourceProxy: DelegateProxy<NSTableView, NSTableViewDataSource>, DelegateProxyType {
    public private(set) weak var tableView: NSTableView?

    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDataSourceProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSTableViewDataSourceProxy(tableView: $0) }
    }

    private weak var _requiredMethodsDataSource: NSTableViewDataSource? = nsTableViewDataSourceNotSet

    public override func setForwardToDelegate(_ forwardToDelegate: NSTableViewDataSource?, retainDelegate: Bool) {
        _requiredMethodsDataSource = forwardToDelegate ?? nsTableViewDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }
}

extension RxNSTableViewDataSourceProxy: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        _requiredMethodsDataSource?.numberOfRows?(in: tableView) ?? nsTableViewDataSourceNotSet.numberOfRows(in: tableView)
    }
}
