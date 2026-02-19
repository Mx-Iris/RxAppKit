import Foundation
import AppKit
import RxSwift
import RxCocoa

class RxNSOutlineViewDataSourceProxy: DelegateProxy<NSOutlineView, NSOutlineViewDataSource>, DelegateProxyType, NSOutlineViewDataSource, RequiredMethodsDelegateProxyType {
    private(set) weak var outlineView: NSOutlineView?

    let _requiredMethodsDelegate: ObjectContainer<NSOutlineViewDataSource> = .init()

//    init(outlineView: NSOutlineView) {
//        self.outlineView = outlineView
//        super.init(parentObject: outlineView, delegateProxy: RxNSOutlineViewDataSourceProxy.self)
//    }

    init<Proxy: DelegateProxyType>(outlineView: NSOutlineView, delegateProxy: Proxy.Type = RxNSOutlineViewDataSourceProxy.self)
    where Proxy: DelegateProxy<ParentObject, Delegate>, Proxy.ParentObject == ParentObject, Proxy.Delegate == Delegate {
        self.outlineView = outlineView
        super.init(parentObject: outlineView, delegateProxy: Proxy.self)
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

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return _requiredMethodsDelegate.object?.outlineView?(outlineView, numberOfChildrenOfItem: item) ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return _requiredMethodsDelegate.object?.outlineView?(outlineView, child: index, ofItem: item) ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return _requiredMethodsDelegate.object?.outlineView?(outlineView, isItemExpandable: item) ?? false
    }
}

class RxNSOutlineViewReorderableDataSourceProxy: RxNSOutlineViewDataSourceProxy {
    
    init(outlineView: NSOutlineView) {
        super.init(outlineView: outlineView, delegateProxy: RxNSOutlineViewReorderableDataSourceProxy.self)
    }
    
    override class func registerKnownImplementations() {
        register { RxNSOutlineViewReorderableDataSourceProxy(outlineView: $0) }
    }
    
    @objc func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, pasteboardWriterForItem: item)
    }

    @objc func outlineView(_ outlineView: NSOutlineView, validateDrop info: any NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, validateDrop: info, proposedItem: item, proposedChildIndex: index) ?? []
    }

    @objc func outlineView(_ outlineView: NSOutlineView, acceptDrop info: any NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, acceptDrop: info, item: item, childIndex: index) ?? false
    }

    @objc(outlineView:draggingSession:willBeginAtPoint:forItems:)
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, draggingSession: session, willBeginAt: screenPoint, forItems: draggedItems)
    }

    @objc(outlineView:draggingSession:endedAtPoint:operation:)
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        _requiredMethodsDelegate.object?.outlineView?(outlineView, draggingSession: session, endedAt: screenPoint, operation: operation)
    }
}
