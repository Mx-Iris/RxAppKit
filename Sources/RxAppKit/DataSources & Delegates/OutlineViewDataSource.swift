//
//  OutlineViewDataSource.swift
//  
//
//  Created by JH on 2023/5/7.
//

import AppKit

protocol OutlineNodeType {
    associatedtype NodeType = Self
    var parent: NodeType? { get }
    var children: [NodeType] { get }
    var isExpandable: Bool { get }
}

extension OutlineNodeType {
    var isExpandable: Bool {
        children.count > 0
    }
}

class OutlineViewDataSource<OutlineNode: OutlineNodeType>: NSObject, NSOutlineViewDataSource {
    public internal(set) var nodes: [OutlineNode] = []
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? OutlineNode else {
            return nodes.count
        }
        return node.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? OutlineNode else {
            return nodes[index]
        }
        return node.children[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? OutlineNode else { return false }
        return node.isExpandable
    }
    
    
    
}
