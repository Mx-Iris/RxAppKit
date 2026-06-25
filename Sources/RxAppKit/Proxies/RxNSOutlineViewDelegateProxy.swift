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
    
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init(parentObject: outlineView, delegateProxy: RxNSOutlineViewDelegateProxy.self)
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
    /// reports `true` because of this `@objc` method). The proxy then forwards
    /// to the adapter, which holds the `PublishSubject` and emits.
    /// `Reactive.proposedSelection()` reads off that adapter subject.
    @objc func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
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
