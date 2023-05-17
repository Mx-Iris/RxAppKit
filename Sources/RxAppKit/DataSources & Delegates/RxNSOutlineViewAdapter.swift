import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

class RxNSOutlineViewAdapter<OutlineNode: OutlineNodeType & Hashable & Differentiable>: OutlineViewAdapter<OutlineNode>, RxNSOutlineViewDataSourceType where OutlineNode.NodeType == OutlineNode {
    typealias Element = [OutlineNode]
    
    private struct IndexedNode: Hashable, Differentiable {
        var node: OutlineNode
        var indexPath: IndexPath
    }

    func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewAdapter<OutlineNode>, newNodes) in
            if dataSource.nodes.isEmpty {
                dataSource.nodes = newNodes
                outlineView.reloadData()
            } else {
                func flattenNodesWithIndexPathIteratively(nodes: [OutlineNode]) -> [IndexedNode] {
                    var flatNodes: [IndexedNode] = []
                    var queue: [IndexedNode] = nodes.enumerated().map { IndexedNode(node: $0.element, indexPath: IndexPath(index: $0.offset)) }

                    while !queue.isEmpty {
                        let indexedNode = queue.removeFirst()
                        flatNodes.append(indexedNode)

                        for (index, child) in indexedNode.node.children.enumerated() {
                            let childIndexPath = indexedNode.indexPath.appending(index)
                            queue.append(IndexedNode(node: child, indexPath: childIndexPath))
                        }
                    }

                    return flatNodes
                }

                let oldFlattenNodes = flattenNodesWithIndexPathIteratively(nodes: dataSource.nodes)
                let newFlattenNodes = flattenNodesWithIndexPathIteratively(nodes: newNodes)

                let changeset = StagedChangeset(source: oldFlattenNodes, target: newFlattenNodes)
                changeset.forEach { change in
                    change.elementInserted.forEach {
                        let indexedNode = newFlattenNodes[$0.element]
                        outlineView.insertItems(at: indexedNode.indexPath.last!.asIndexSet, inParent: indexedNode.node.parent)
                    }
                    change.elementDeleted.forEach {
                        let indexedNode = newFlattenNodes[$0.element]
                        outlineView.removeItems(at: indexedNode.indexPath.last!.asIndexSet, inParent: indexedNode.node.parent)
                    }
                    change.elementMoved.forEach {
                        let sourceIndexedNode = change.data[$0.source.element]
                        let targetIndexedNode = change.data[$0.target.element]
                        outlineView.moveItem(at: sourceIndexedNode.indexPath.last!, inParent: sourceIndexedNode.node.parent, to: targetIndexedNode.indexPath.last!, inParent: targetIndexedNode.node.parent)
                    }

                    change.elementUpdated.forEach {
                        let indexedNode = change.data[$0.element]
                        outlineView.reloadItem(indexedNode.node)
                    }
                }
            }

        }.on(observedEvent)
    }
}

extension Int {
    fileprivate var asIndexSet: IndexSet {
        IndexSet(integer: self)
    }
}
