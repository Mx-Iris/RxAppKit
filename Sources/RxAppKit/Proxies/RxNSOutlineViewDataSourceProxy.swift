//
//  RxNSOutlineViewDataSourceProxy.swift
//
//
//  Created by JH on 2023/5/8.
//

import Foundation
import AppKit
import RxSwift
import RxCocoa

class RxNSOutlineViewDataSourceProxy: DelegateProxy<NSOutlineView, NSOutlineViewDataSource>, DelegateProxyType, NSOutlineViewDataSource {
    public private(set) weak var outlineView: NSOutlineView?

    private weak var _requiredMethodDataSource: NSOutlineViewDataSource?
    
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init(parentObject: outlineView, delegateProxy: RxNSOutlineViewDataSourceProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSOutlineViewDataSourceProxy(outlineView: $0) }
    }

    static func currentDelegate(for object: NSOutlineView) -> NSOutlineViewDataSource? {
        object.dataSource
    }

    static func setCurrentDelegate(_ delegate: NSOutlineViewDataSource?, to object: NSOutlineView) {
        object.dataSource = delegate
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return _requiredMethodDataSource?.outlineView?(outlineView, numberOfChildrenOfItem: item) ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return _requiredMethodDataSource?.outlineView?(outlineView, child: index, ofItem: item) ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return _requiredMethodDataSource?.outlineView?(outlineView, isItemExpandable: item) ?? false
    }
    
    override func setForwardToDelegate(_ delegate: DelegateProxy<NSOutlineView, NSOutlineViewDataSource>.Delegate?, retainDelegate: Bool) {
        _requiredMethodDataSource = delegate
        super.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    }
}
