import Foundation

/// Outline nodes that allow their children to be mutated.
public protocol MutableOutlineNodeType: OutlineNodeType {
    var children: [Self] { get set }
}

public extension OutlineNodeType where Self: MutableOutlineNodeType {
    /// Applies an `OutlineMove` to the given root nodes.
    ///
    /// - Note: Paths are based on the outline state before the move is applied.
    static func apply(_ move: OutlineMove, to roots: inout [Self]) {
        guard let sourceChildren = children(at: move.sourceParentPath, in: roots) else { return }
        guard let destinationChildren = children(at: move.destinationParentPath, in: roots) else { return }

        let sortedAscending = move.sourceIndexes.sorted()
        if sortedAscending.isEmpty { return }
        guard sortedAscending.allSatisfy({ $0 >= 0 && $0 < sourceChildren.count }) else { return }

        var targetIndex = move.destinationIndex
        let sameParent = move.sourceParentPath == move.destinationParentPath
        if sameParent {
            for index in move.sourceIndexes.sorted(by: >) where index < targetIndex {
                targetIndex -= 1
            }
        }

        var updatedSource = sourceChildren
        let moved = sortedAscending.map { updatedSource[$0] }
        for index in move.sourceIndexes.sorted(by: >) {
            updatedSource.remove(at: index)
        }

        if sameParent {
            var children = updatedSource
            let clampedTarget = max(0, min(targetIndex, children.count))
            for (offset, node) in moved.enumerated() {
                children.insert(node, at: clampedTarget + offset)
            }
            setChildren(children, at: move.sourceParentPath, in: &roots)
            return
        }

        setChildren(updatedSource, at: move.sourceParentPath, in: &roots)

        var updatedDestination = destinationChildren
        let clampedTarget = max(0, min(targetIndex, updatedDestination.count))
        for (offset, node) in moved.enumerated() {
            updatedDestination.insert(node, at: clampedTarget + offset)
        }
        setChildren(updatedDestination, at: move.destinationParentPath, in: &roots)
    }

    private static func children(at path: IndexPath?, in roots: [Self]) -> [Self]? {
        guard let path, !path.isEmpty else { return roots }
        var current = roots
        for index in path {
            guard index >= 0 && index < current.count else { return nil }
            current = current[index].children
        }
        return current
    }

    private static func setChildren(_ children: [Self], at path: IndexPath?, in roots: inout [Self]) {
        guard let path, !path.isEmpty else {
            roots = children
            return
        }
        modifyChildren(at: path, in: &roots) { $0 = children }
    }

    private static func modifyChildren(at path: IndexPath, in nodes: inout [Self], _ body: (inout [Self]) -> Void) {
        guard !path.isEmpty else {
            body(&nodes)
            return
        }
        let index = path[0]
        guard index >= 0 && index < nodes.count else { return }
        var node = nodes[index]
        var children = node.children
        let remaining = IndexPath(indexes: Array(path.dropFirst()))
        modifyChildren(at: remaining, in: &children, body)
        node.children = children
        nodes[index] = node
    }
}
