import Foundation
import AppKit
import RxSwift
import RxCocoa

class RxNSOutlineViewDataSourceProxy: DelegateProxy<NSOutlineView, NSOutlineViewDataSource>, DelegateProxyType, NSOutlineViewDataSource, RequiredMethodsDelegateProxyType {
    private(set) weak var outlineView: NSOutlineView?

    let _requiredMethodsDelegate: ObjectContainer<NSOutlineViewDataSource> = .init()

    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init(parentObject: outlineView, delegateProxy: RxNSOutlineViewDataSourceProxy.self)
    }

    class func registerKnownImplementations() {
        register { RxNSOutlineViewDataSourceProxy(outlineView: $0) }
    }

    static func currentDelegate(for object: NSOutlineView) -> NSOutlineViewDataSource? {
        object.dataSource
    }

    static func setCurrentDelegate(_ delegate: NSOutlineViewDataSource?, to object: NSOutlineView) {
        object.dataSource = delegate
    }

    // MARK: - Required Data Source

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, numberOfChildrenOfItem: item) ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, child: index, ofItem: item) ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, isItemExpandable: item) ?? false
    }

    // MARK: - Drag & Drop

    private static let dragDropSelectors: Set<Selector> = [
        #selector(NSOutlineViewDataSource.outlineView(_:pasteboardWriterForItem:)),
        #selector(NSOutlineViewDataSource.outlineView(_:validateDrop:proposedItem:proposedChildIndex:)),
        #selector(NSOutlineViewDataSource.outlineView(_:acceptDrop:item:childIndex:)),
        #selector(NSOutlineViewDataSource.outlineView(_:draggingSession:willBeginAt:forItems:)),
        #selector(NSOutlineViewDataSource.outlineView(_:draggingSession:endedAt:operation:)),
    ]

    // Only claim support for drag-and-drop when the adapter or the user's
    // custom data source actually implements the method.  This prevents the
    // proxy from swallowing calls that should reach forwardToDelegate, and
    // avoids telling AppKit we support drag-and-drop when nobody handles it.
    override func responds(to aSelector: Selector!) -> Bool {
        if let aSelector, Self.dragDropSelectors.contains(aSelector) {
            return _requiredMethodsDelegate.object?.responds(to: aSelector) == true
                || forwardToDelegate()?.responds(to: aSelector) == true
        }
        return super.responds(to: aSelector)
    }

    @objc func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSOutlineViewDataSource.outlineView(_:pasteboardWriterForItem:))) {
            return delegate.outlineView?(outlineView, pasteboardWriterForItem: item)
        }
        return forwardToDelegate()?.outlineView?(outlineView, pasteboardWriterForItem: item)
    }

    @objc func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSOutlineViewDataSource.outlineView(_:validateDrop:proposedItem:proposedChildIndex:))) {
            return delegate.outlineView?(outlineView, validateDrop: info, proposedItem: item, proposedChildIndex: index) ?? []
        }
        return forwardToDelegate()?.outlineView?(outlineView, validateDrop: info, proposedItem: item, proposedChildIndex: index) ?? []
    }

    @objc func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: #selector(NSOutlineViewDataSource.outlineView(_:acceptDrop:item:childIndex:))) {
            return delegate.outlineView?(outlineView, acceptDrop: info, item: item, childIndex: index) ?? false
        }
        return forwardToDelegate()?.outlineView?(outlineView, acceptDrop: info, item: item, childIndex: index) ?? false
    }

    @objc(outlineView:draggingSession:willBeginAtPoint:forItems:)
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        let selector = #selector(NSOutlineViewDataSource.outlineView(_:draggingSession:willBeginAt:forItems:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            delegate.outlineView?(outlineView, draggingSession: session, willBeginAt: screenPoint, forItems: draggedItems)
            return
        }
        forwardToDelegate()?.outlineView?(outlineView, draggingSession: session, willBeginAt: screenPoint, forItems: draggedItems)
    }

    @objc(outlineView:draggingSession:endedAtPoint:operation:)
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        let selector = #selector(NSOutlineViewDataSource.outlineView(_:draggingSession:endedAt:operation:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            delegate.outlineView?(outlineView, draggingSession: session, endedAt: screenPoint, operation: operation)
            return
        }
        forwardToDelegate()?.outlineView?(outlineView, draggingSession: session, endedAt: screenPoint, operation: operation)
    }
}
