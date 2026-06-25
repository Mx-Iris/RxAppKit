//
//  RxNSOutlineViewDelegateProxy.swift
//
//
//  Created by JH on 2023/5/8.
//

import Foundation
import AppKit
import RxSwift
import RxCocoa

class RxNSOutlineViewDelegateProxy: DelegateProxy<NSOutlineView, NSOutlineViewDelegate>, DelegateProxyType, NSOutlineViewDelegate {
    public private(set) weak var outlineView: NSOutlineView?

    weak var _requiredMethodDelegate: NSOutlineViewDelegate?

    /// Subject lives on the proxy (rather than the data-source adapter) so
    /// `Reactive.proposedSelection()` can resolve it at subscription time
    /// regardless of whether `rx.nodes` / `rx.sections` has installed an
    /// adapter yet. This is the RxCocoa-recommended pattern for delegate
    /// methods the proxy must implement itself: `methodInvoked(_:)` does NOT
    /// intercept selectors the proxy already provides an implementation for
    /// (see DelegateProxy "Delegate proxy is already implementing ..." note).
    let _proposedSelection = PublishSubject<NSOutlineView.ProposedSelection>()

    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init(parentObject: outlineView, delegateProxy: RxNSOutlineViewDelegateProxy.self)
    }

    deinit {
        _proposedSelection.onCompleted()
    }

    static func registerKnownImplementations() {
        register { RxNSOutlineViewDelegateProxy(outlineView: $0) }
    }

    static func currentDelegate(for object: NSOutlineView) -> NSOutlineViewDelegate? {
        object.delegate
    }

    static func setCurrentDelegate(_ delegate: NSOutlineViewDelegate?, to object: NSOutlineView) {
        object.delegate = delegate
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        _requiredMethodDelegate?.outlineView?(outlineView, viewFor: tableColumn, item: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        _requiredMethodDelegate?.outlineView?(outlineView, rowViewForItem: item)
    }

    // MARK: - Group items (Sections)

    /// `isGroupItem` is optional, so it must only be advertised when something
    /// downstream actually implements it. Claiming it unconditionally would let a
    /// plain (non-sectioned) `rx.nodes` binding shadow a user delegate's own
    /// `isGroupItem`.
    private static let groupItemSelectors: Set<Selector> = [
        #selector(NSOutlineViewDelegate.outlineView(_:isGroupItem:)),
    ]

    override func responds(to aSelector: Selector!) -> Bool {
        if let aSelector, Self.groupItemSelectors.contains(aSelector) {
            return _requiredMethodDelegate?.responds(to: aSelector) == true
                || forwardToDelegate()?.responds(to: aSelector) == true
        }
        return super.responds(to: aSelector)
    }

    @objc func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        let selector = #selector(NSOutlineViewDelegate.outlineView(_:isGroupItem:))
        if let delegate = _requiredMethodDelegate, delegate.responds(to: selector) {
            return delegate.outlineView?(outlineView, isGroupItem: item) ?? false
        }
        return forwardToDelegate()?.outlineView?(outlineView, isGroupItem: item) ?? false
    }

    // MARK: - User-initiated selection

    /// Implemented here so AppKit invokes the proxy (whose `responds(to:)`
    /// reports `true` because of this `@objc` method). Emission goes to the
    /// proxy-owned `_proposedSelection` subject first so subscribers can
    /// observe events regardless of when (or whether) a data-source adapter
    /// installs itself. Forwarding to `_requiredMethodDelegate` /
    /// `forwardToDelegate()` is preserved so a downstream delegate can still
    /// customize the proposed index set, and its return value wins.
    @objc func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        _proposedSelection.onNext(.init(indexes: proposedSelectionIndexes, triggeringEvent: outlineView.window?.currentEvent))
        let selector = #selector(NSOutlineViewDelegate.outlineView(_:selectionIndexesForProposedSelection:))
        if let delegate = _requiredMethodDelegate, delegate.responds(to: selector) {
            return delegate.outlineView?(outlineView, selectionIndexesForProposedSelection: proposedSelectionIndexes) ?? proposedSelectionIndexes
        }
        if let delegate = forwardToDelegate(), delegate.responds(to: selector) {
            return delegate.outlineView?(outlineView, selectionIndexesForProposedSelection: proposedSelectionIndexes) ?? proposedSelectionIndexes
        }
        return proposedSelectionIndexes
    }

    func setRequiredMethodDelegate(_ requiredMethodDelegate: NSOutlineViewDelegate) -> Disposable {
        _requiredMethodDelegate = requiredMethodDelegate
        return Disposables.create { [weak self] in
            guard let self = self else { return }
            self._requiredMethodDelegate = nil
        }
    }
    
}
