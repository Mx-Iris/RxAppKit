import AppKit
import RxSwift
import RxCocoa

extension NSTableView: @retroactive HasDataSource {
    public typealias DataSource = NSTableViewDataSource
}

class RxNSTableViewDataSourceProxy: DelegateProxy<NSTableView, NSTableViewDataSource>, RequiredMethodsDelegateProxyType {

    public private(set) weak var tableView: NSTableView?

    init(tableView: NSTableView) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDataSourceProxy.self)
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

    // MARK: - Drag & Drop

    private static let dragDropSelectors: Set<Selector> = [
        #selector(NSTableViewDataSource.tableView(_:pasteboardWriterForRow:)),
        #selector(NSTableViewDataSource.tableView(_:validateDrop:proposedRow:proposedDropOperation:)),
        #selector(NSTableViewDataSource.tableView(_:acceptDrop:row:dropOperation:)),
        #selector(NSTableViewDataSource.tableView(_:draggingSession:willBeginAt:forRowIndexes:)),
        #selector(NSTableViewDataSource.tableView(_:draggingSession:endedAt:operation:)),
    ]

    override func responds(to aSelector: Selector!) -> Bool {
        if let aSelector, Self.dragDropSelectors.contains(aSelector) {
            return _requiredMethodsDelegate.object?.responds(to: aSelector) == true
                || forwardToDelegate()?.responds(to: aSelector) == true
        }
        return super.responds(to: aSelector)
    }

    @objc public func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSTableViewDataSource.tableView(_:pasteboardWriterForRow:))) {
            return delegate.tableView?(tableView, pasteboardWriterForRow: row)
        }
        return forwardToDelegate()?.tableView?(tableView, pasteboardWriterForRow: row)
    }

    @objc public func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSTableViewDataSource.tableView(_:validateDrop:proposedRow:proposedDropOperation:))) {
            return delegate.tableView?(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation) ?? []
        }
        return forwardToDelegate()?.tableView?(tableView, validateDrop: info, proposedRow: row, proposedDropOperation: dropOperation) ?? []
    }

    @objc public func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSTableViewDataSource.tableView(_:acceptDrop:row:dropOperation:))) {
            return delegate.tableView?(tableView, acceptDrop: info, row: row, dropOperation: dropOperation) ?? false
        }
        return forwardToDelegate()?.tableView?(tableView, acceptDrop: info, row: row, dropOperation: dropOperation) ?? false
    }

    @objc(tableView:draggingSession:willBeginAtPoint:forRowIndexes:)
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        let selector = #selector(NSTableViewDataSource.tableView(_:draggingSession:willBeginAt:forRowIndexes:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            delegate.tableView?(tableView, draggingSession: session, willBeginAt: screenPoint, forRowIndexes: rowIndexes)
            return
        }
        forwardToDelegate()?.tableView?(tableView, draggingSession: session, willBeginAt: screenPoint, forRowIndexes: rowIndexes)
    }

    @objc(tableView:draggingSession:endedAtPoint:operation:)
    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        let selector = #selector(NSTableViewDataSource.tableView(_:draggingSession:endedAt:operation:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            delegate.tableView?(tableView, draggingSession: session, endedAt: screenPoint, operation: operation)
            return
        }
        forwardToDelegate()?.tableView?(tableView, draggingSession: session, endedAt: screenPoint, operation: operation)
    }
}
