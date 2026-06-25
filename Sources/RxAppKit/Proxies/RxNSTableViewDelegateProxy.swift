import AppKit
import RxSwift
import RxCocoa

extension NSTableView: @retroactive HasDelegate {
    public typealias Delegate = NSTableViewDelegate
}

class RxNSTableViewDelegateProxy: DelegateProxy<NSTableView, NSTableViewDelegate>, RequiredMethodsDelegateProxyType, NSTableViewDelegate {
    public private(set) weak var tableView: NSTableView?

    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDelegateProxy.self)
    }

    deinit {
        _proposedSelection.onCompleted()
    }

    public static func registerKnownImplementations() {
        register { RxNSTableViewDelegateProxy(tableView: $0) }
    }

    let _requiredMethodsDelegate: ObjectContainer<NSTableViewDelegate> = .init()

    /// Subject lives on the proxy (rather than the data-source adapter) so
    /// `Reactive.proposedSelection()` can resolve it at subscription time
    /// regardless of whether `rx.items` / `rx.sections` has installed an
    /// adapter yet. This is the RxCocoa-recommended pattern for delegate
    /// methods the proxy must implement itself: `methodInvoked(_:)` does NOT
    /// intercept selectors the proxy already provides an implementation for
    /// (see DelegateProxy "Delegate proxy is already implementing ..." note).
    let _proposedSelection = PublishSubject<NSTableView.ProposedSelection>()

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        _requiredMethodsDelegate.object?.tableView?(tableView, viewFor: tableColumn, row: row)
    }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        _requiredMethodsDelegate.object?.tableView?(tableView, rowViewForRow: row)
    }

    // MARK: - Group rows (Sections)

    /// `isGroupRow` is optional, so it must only be advertised when something
    /// downstream actually implements it. Claiming it unconditionally would let a
    /// plain (non-sectioned) `rx.items` binding shadow a user delegate's own
    /// `isGroupRow`. Mirrors the data-source proxy's drag-and-drop selector gate.
    private static let groupRowSelectors: Set<Selector> = [
        #selector(NSTableViewDelegate.tableView(_:isGroupRow:)),
    ]

    override func responds(to aSelector: Selector!) -> Bool {
        if let aSelector, Self.groupRowSelectors.contains(aSelector) {
            return _requiredMethodsDelegate.object?.responds(to: aSelector) == true
                || forwardToDelegate()?.responds(to: aSelector) == true
        }
        return super.responds(to: aSelector)
    }

    @objc public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        let selector = #selector(NSTableViewDelegate.tableView(_:isGroupRow:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            return delegate.tableView?(tableView, isGroupRow: row) ?? false
        }
        return forwardToDelegate()?.tableView?(tableView, isGroupRow: row) ?? false
    }

    // MARK: - User-initiated selection

    /// Implemented here so AppKit invokes the proxy (whose `responds(to:)`
    /// reports `true` because of this `@objc` method). Emission goes to the
    /// proxy-owned `_proposedSelection` subject first so subscribers can
    /// observe events regardless of when (or whether) a data-source adapter
    /// installs itself. Forwarding to `_requiredMethodsDelegate` /
    /// `forwardToDelegate()` is preserved so a downstream delegate can still
    /// customize the proposed index set, and its return value wins.
    @objc public func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        _proposedSelection.onNext(.init(indexes: proposedSelectionIndexes, triggeringEvent: tableView.window?.currentEvent))
        let selector = #selector(NSTableViewDelegate.tableView(_:selectionIndexesForProposedSelection:))
        if let delegate = _requiredMethodsDelegate.object, delegate.responds(to: selector) {
            return delegate.tableView?(tableView, selectionIndexesForProposedSelection: proposedSelectionIndexes) ?? proposedSelectionIndexes
        }
        if let delegate = forwardToDelegate(), delegate.responds(to: selector) {
            return delegate.tableView?(tableView, selectionIndexesForProposedSelection: proposedSelectionIndexes) ?? proposedSelectionIndexes
        }
        return proposedSelectionIndexes
    }
}
