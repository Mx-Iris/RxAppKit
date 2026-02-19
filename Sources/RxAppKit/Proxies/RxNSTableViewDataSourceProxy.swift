import AppKit
import RxSwift
import RxCocoa

extension NSTableView: @retroactive HasDataSource {
    public typealias DataSource = NSTableViewDataSource
}

class RxNSTableViewDataSourceProxy: DelegateProxy<NSTableView, NSTableViewDataSource>, RequiredMethodsDelegateProxyType {

    public private(set) weak var tableView: NSTableView?

    init<Proxy: DelegateProxyType>(tableView: NSTableView, delegateProxy: Proxy.Type = RxNSTableViewDataSourceProxy.self)
    where Proxy: DelegateProxy<ParentObject, Delegate>, Proxy.ParentObject == ParentObject, Proxy.Delegate == Delegate {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: Proxy.self)
    }

    class func registerKnownImplementations() {
        register { RxNSTableViewDataSourceProxy(tableView: $0) }
    }

    let _requiredMethodsDelegate: ObjectContainer<NSTableViewDataSource> = .init()

    static func currentDelegate(for object: NSTableView) -> NSTableViewDataSource? {
        object.dataSource
    }

    static func setCurrentDelegate(_ delegate: NSTableViewDataSource?, to object: NSTableView) {
        object.dataSource = delegate
    }
}

extension RxNSTableViewDataSourceProxy: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        _requiredMethodsDelegate.object?.numberOfRows?(in: tableView) ?? 0
    }
}

class RxNSTableViewReorderableDataSourceProxy: RxNSTableViewDataSourceProxy {

    init(tableView: NSTableView) {
        super.init(tableView: tableView, delegateProxy: RxNSTableViewReorderableDataSourceProxy.self)
    }

    override class func registerKnownImplementations() {
        register { RxNSTableViewReorderableDataSourceProxy(tableView: $0) }
    }

    // MARK: - Drag & Drop forwarding

    @objc func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        _requiredMethodsDelegate.object?.tableView?(tableView, pasteboardWriterForRow: row)
    }

    @objc func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        _requiredMethodsDelegate.object?.tableView?(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation) ?? []
    }

    @objc func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        _requiredMethodsDelegate.object?.tableView?(tableView, acceptDrop: info, row: row, dropOperation: dropOperation) ?? false
    }

    @objc(tableView:draggingSession:willBeginAtPoint:forRowIndexes:)
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        _requiredMethodsDelegate.object?.tableView?(tableView, draggingSession: session, willBeginAt: screenPoint, forRowIndexes: rowIndexes)
    }

    @objc(tableView:draggingSession:endedAtPoint:operation:)
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        _requiredMethodsDelegate.object?.tableView?(tableView, draggingSession: session, endedAt: screenPoint, operation: operation)
    }
}
