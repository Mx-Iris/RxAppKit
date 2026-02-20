import Foundation

public protocol OutlineNodeType {
    var children: [Self] { get }
}

extension OutlineNodeType {
    public var isExpandable: Bool {
        children.count > 0
    }
}

/// Describes a move operation inside an outline view.
/// Paths are based on the outline state before the move is applied.
public struct OutlineMove: Equatable {
    /// The index path of the source parent item. `nil` means the root level.
    public let sourceParentPath: IndexPath?
    /// The indexes (within the source parent) of the moved items.
    public let sourceIndexes: IndexSet
    /// The index path of the destination parent item. `nil` means the root level.
    public let destinationParentPath: IndexPath?
    /// The destination index (within the destination parent) where the items are inserted.
    public let destinationIndex: Int
    /// Whether the drop was performed "on" an item (vs. between items).
    public let isDropOnItem: Bool

    public init(
        sourceParentPath: IndexPath?,
        sourceIndexes: IndexSet,
        destinationParentPath: IndexPath?,
        destinationIndex: Int,
        isDropOnItem: Bool
    ) {
        self.sourceParentPath = sourceParentPath
        self.sourceIndexes = sourceIndexes
        self.destinationParentPath = destinationParentPath
        self.destinationIndex = destinationIndex
        self.isDropOnItem = isDropOnItem
    }
}

extension OutlineMove {
    /// Applies this move to the given root nodes array.
    ///
    /// The `setChildren` closure is called to update a parent node's children.
    /// This design works with any children storage pattern (e.g. `private(set)`,
    /// internal backing store) without requiring a specific protocol conformance.
    ///
    /// Example:
    ///
    ///     move.apply(to: &nodes) { parent, newChildren in
    ///         parent.internalChildren = newChildren
    ///     }
    ///
    /// - Parameters:
    ///   - roots: The root-level nodes array to modify.
    ///   - setChildren: A closure that sets new children on a parent node.
    public func apply<Node: OutlineNodeType>(
        to roots: inout [Node],
        setChildren: (_ parent: Node, _ newChildren: [Node]) -> Void
    ) {
        func children(at path: IndexPath?) -> [Node]? {
            guard let path, !path.isEmpty else { return roots }
            var current = roots
            for index in path {
                guard index >= 0, index < current.count else { return nil }
                current = current[index].children
            }
            return current
        }

        func node(at path: IndexPath) -> Node? {
            var current = roots
            for (i, index) in path.enumerated() {
                guard index >= 0, index < current.count else { return nil }
                if i == path.count - 1 { return current[index] }
                current = current[index].children
            }
            return nil
        }

        func set(_ newChildren: [Node], at path: IndexPath?) {
            if let path, !path.isEmpty, let parent = node(at: path) {
                setChildren(parent, newChildren)
            } else {
                roots = newChildren
            }
        }

        guard let sourceChildren = children(at: sourceParentPath) else { return }
        guard let destinationChildren = children(at: destinationParentPath) else { return }

        let sortedAscending = sourceIndexes.sorted()
        guard !sortedAscending.isEmpty else { return }
        guard sortedAscending.allSatisfy({ $0 >= 0 && $0 < sourceChildren.count }) else { return }

        let sameParent = sourceParentPath == destinationParentPath
        var targetIndex = destinationIndex
        if sameParent {
            for index in sourceIndexes.sorted(by: >) where index < targetIndex {
                targetIndex -= 1
            }
        }

        let moved = sortedAscending.map { sourceChildren[$0] }
        var updatedSource = sourceChildren
        for index in sourceIndexes.sorted(by: >) {
            updatedSource.remove(at: index)
        }

        if sameParent {
            let clamped = max(0, min(targetIndex, updatedSource.count))
            for (offset, n) in moved.enumerated() {
                updatedSource.insert(n, at: clamped + offset)
            }
            set(updatedSource, at: sourceParentPath)
            return
        }

        // Cross-parent: apply source removal first, then destination insertion
        set(updatedSource, at: sourceParentPath)

        var updatedDestination = destinationChildren
        let clamped = max(0, min(targetIndex, updatedDestination.count))
        for (offset, n) in moved.enumerated() {
            updatedDestination.insert(n, at: clamped + offset)
        }
        set(updatedDestination, at: destinationParentPath)
    }

    /// Applies this move to the root-level nodes array only.
    ///
    /// This is a convenience for root-level-only reordering (where both
    /// `sourceParentPath` and `destinationParentPath` are `nil`).
    /// Does nothing if the move involves non-root parents.
    ///
    /// - Parameter roots: The root-level nodes array to modify in place.
    public func applyToRoots<Node>(_ roots: inout [Node]) {
        guard sourceParentPath == nil, destinationParentPath == nil else { return }

        let sortedAscending = sourceIndexes.sorted()
        guard !sortedAscending.isEmpty else { return }
        guard sortedAscending.allSatisfy({ $0 >= 0 && $0 < roots.count }) else { return }

        var targetIndex = destinationIndex
        for index in sourceIndexes.sorted(by: >) where index < targetIndex {
            targetIndex -= 1
        }

        let moved = sortedAscending.map { roots[$0] }
        for index in sourceIndexes.sorted(by: >) {
            roots.remove(at: index)
        }

        let clamped = max(0, min(targetIndex, roots.count))
        for (offset, n) in moved.enumerated() {
            roots.insert(n, at: clamped + offset)
        }
    }
}
