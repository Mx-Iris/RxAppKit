import AppKit
import RxSwift
import RxCocoa

extension NSTableView: @retroactive HasDataSource {
    public typealias DataSource = NSTableViewDataSource
}

class RxNSTableViewDataSourceProxy: DelegateProxy<NSTableView, NSTableViewDataSource>, RequiredMethodDelegateProxyType {
    
    
    public private(set) weak var tableView: NSTableView?

    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDataSourceProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSTableViewDataSourceProxy(tableView: $0) }
    }

    let _requiredMethodsDelegate: ObjectContainer<NSTableViewDataSource> = .init()

//    public override func setForwardToDelegate(_ forwardToDelegate: NSTableViewDataSource?, retainDelegate: Bool) {
//        _requiredMethodsDataSource = forwardToDelegate ?? nsTableViewDataSourceNotSet
//        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
//    }

}

extension RxNSTableViewDataSourceProxy: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        _requiredMethodsDelegate.object?.numberOfRows?(in: tableView) ?? 0
    }
}
