import AppKit
import DifferenceKit
import RxSwift
import RxCocoa
import Testing
@testable import RxAppKit

private struct TestNode: OutlineNodeType, Hashable, Differentiable {
    let id: String
    let children: [TestNode]

    init(_ id: String, children: [TestNode] = []) {
        self.id = id
        self.children = children
    }

    // Identity-based equality so NSOutlineView preserves expansion state across updates.
    static func == (lhs: TestNode, rhs: TestNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var differenceIdentifier: String { id }

    // Recursive structural comparison so DifferenceKit detects subtree changes
    // even though `==` ignores children.
    func isContentEqual(to source: TestNode) -> Bool {
        guard id == source.id, children.count == source.children.count else { return false }
        return zip(children, source.children).allSatisfy { $0.isContentEqual(to: $1) }
    }
}

@MainActor
@Suite("RxNSOutlineViewAdapter")
final class RxNSOutlineViewAdapterTests {
    private let window: NSWindow
    private let outlineView: NSOutlineView

    init() {
        let outlineView = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        column.width = 180
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        scrollView.documentView = outlineView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 400),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        // The reload extension early-returns to reloadData() when window is nil,
        // so tests need a real window to exercise the staged-changeset path.
        window.makeKeyAndOrderFront(nil)

        self.outlineView = outlineView
        self.window = window
    }

    private func makeArrayAdapter(options: RxNSOutlineViewAdapterOptions = .diffable) -> RxNSOutlineViewAdapter<TestNode> {
        let adapter = RxNSOutlineViewAdapter<TestNode>(
            options: options,
            cellViewProvider: { _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func makeRootNodeAdapter(options: RxNSOutlineViewAdapterOptions = .diffable) -> RxNSOutlineViewRootNodeAdapter<TestNode> {
        let adapter = RxNSOutlineViewRootNodeAdapter<TestNode>(
            options: options,
            cellViewProvider: { _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func rowIDs() -> [String] {
        (0..<outlineView.numberOfRows).compactMap {
            (outlineView.item(atRow: $0) as? TestNode)?.id
        }
    }

    // MARK: - Flat reload basics

    @Test func initialLoad() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"), TestNode("C"),
        ]))
        #expect(rowIDs() == ["A", "B", "C"])
        #expect(adapter.nodes.map(\.id) == ["A", "B", "C"])
    }

    @Test func insertAndDelete() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"), TestNode("C"),
        ]))
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("D"),
        ]))
        #expect(rowIDs() == ["A", "D"])
    }

    @Test func noChangeIsNoop() {
        let adapter = makeArrayAdapter()
        let nodes = [TestNode("A"), TestNode("B")]
        adapter.outlineView(outlineView, observedEvent: .next(nodes))
        adapter.outlineView(outlineView, observedEvent: .next(nodes))
        #expect(rowIDs() == ["A", "B"])
    }

    // MARK: - Reorders

    /// `[A, B, C] → [X, B, C, A]` is a known-tricky combination: DifferenceKit emits
    /// `inserted=[0]` plus `moved=[1→1, 2→2]` and relies on the `moveItem` offset
    /// translation (the same one DifferenceKit applies in its `NSTableView` extension)
    /// to land everything at the right index. This test pins that the animated path
    /// produces the same final order as the new array.
    @Test func moveCombinedWithInsertProducesCorrectOrder() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"), TestNode("C"),
        ]))
        // Old: [A, B, C]
        // New: [X, B, C, A]  →  insert X at 0 + move A from 0 to 3
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("X"), TestNode("B"), TestNode("C"), TestNode("A"),
        ]))
        #expect(rowIDs() == ["X", "B", "C", "A"])
    }

    @Test func multipleMoves() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"), TestNode("C"), TestNode("D"),
        ]))
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("D"), TestNode("C"), TestNode("B"), TestNode("A"),
        ]))
        #expect(rowIDs() == ["D", "C", "B", "A"])
    }

    // MARK: - Subtree update propagation

    /// `elementUpdated` falls back to `reloadData()` so subtree changes always
    /// surface, even when nodes are value-typed (where `reloadItem(_, reloadChildren:)`
    /// would receive stale child references via the data source callback).
    @Test func subtreeAddChildPropagates() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("Parent", children: [TestNode("A"), TestNode("B")]),
        ]))
        outlineView.expandItem(TestNode("Parent"))
        #expect(rowIDs() == ["Parent", "A", "B"])

        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("Parent", children: [TestNode("A"), TestNode("B"), TestNode("C")]),
        ]))
        #expect(rowIDs() == ["Parent", "A", "B", "C"])
    }

    @Test func subtreeRemoveChildPropagates() {
        let adapter = makeArrayAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("Parent", children: [TestNode("A"), TestNode("B"), TestNode("C")]),
        ]))
        outlineView.expandItem(TestNode("Parent"))
        #expect(rowIDs() == ["Parent", "A", "B", "C"])

        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("Parent", children: [TestNode("A")]),
        ]))
        #expect(rowIDs() == ["Parent", "A"])
    }

    // MARK: - Threshold fallback

    @Test func thresholdFallbackKeepsCorrectFinalState() {
        let adapter = makeArrayAdapter()
        adapter.animatedReloadThreshold = 3
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"),
        ]))

        // 8 simultaneous inserts vastly exceeds the threshold of 3,
        // forcing the interrupt closure to return `true` and fall back
        // to `reloadData()`. The final state must still be correct.
        let many = (0..<8).map { TestNode("N\($0)") }
        adapter.outlineView(outlineView, observedEvent: .next(many))
        #expect(rowIDs() == many.map(\.id))
        #expect(adapter.nodes.map(\.id) == many.map(\.id))
    }

    @Test func thresholdHighEnoughTakesAnimatedPath() {
        let adapter = makeArrayAdapter()
        adapter.animatedReloadThreshold = 1000
        adapter.outlineView(outlineView, observedEvent: .next([
            TestNode("A"), TestNode("B"),
        ]))
        let updated = [TestNode("A"), TestNode("X"), TestNode("B")]
        adapter.outlineView(outlineView, observedEvent: .next(updated))
        #expect(rowIDs() == ["A", "X", "B"])
    }

    // MARK: - Root-node adapter

    @Test func rootNodeAdapterInitialLoad() {
        let adapter = makeRootNodeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            TestNode("Root", children: [TestNode("A"), TestNode("B")])
        ))
        #expect(rowIDs() == ["Root"])
        outlineView.expandItem(TestNode("Root"))
        #expect(rowIDs() == ["Root", "A", "B"])
    }

    @Test func rootNodeAdapterSubtreeUpdate() {
        let adapter = makeRootNodeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            TestNode("Root", children: [TestNode("A")])
        ))
        outlineView.expandItem(TestNode("Root"))
        #expect(rowIDs() == ["Root", "A"])

        adapter.outlineView(outlineView, observedEvent: .next(
            TestNode("Root", children: [TestNode("A"), TestNode("B")])
        ))
        #expect(rowIDs() == ["Root", "A", "B"])
    }

    @Test func rootNodeAdapterReplaceRoot() {
        let adapter = makeRootNodeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(TestNode("Root1")))
        #expect(rowIDs() == ["Root1"])

        adapter.outlineView(outlineView, observedEvent: .next(TestNode("Root2")))
        #expect(rowIDs() == ["Root2"])
    }
}

private final class MutableNode: OutlineNodeType {
    let id: String
    var children: [MutableNode]

    init(_ id: String, children: [MutableNode] = []) {
        self.id = id
        self.children = children
    }
}

// Identity-based equality so `NSOutlineView`'s item-to-row mapping treats each
// `MutableNode` instance as a unique item and so we can store nodes in
// `Set`/`Dictionary` if any code path needs to.
extension MutableNode: Hashable {
    static func == (lhs: MutableNode, rhs: MutableNode) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

@Suite("OutlineMove apply")
struct OutlineMoveApplyTests {
    private func ids(_ nodes: [MutableNode]) -> [String] { nodes.map(\.id) }

    // MARK: - Same-parent moves

    @Test func applyRootOnly_MoveDown() {
        var roots = [MutableNode("A"), MutableNode("B"), MutableNode("C"), MutableNode("D")]
        let move = OutlineMove(
            sourceParentPath: nil,
            sourceIndexes: IndexSet([0]),
            destinationParentPath: nil,
            destinationIndex: 4,
            isDropOnItem: false
        )
        move.apply(to: &roots) { $0.children = $1 }
        #expect(ids(roots) == ["B", "C", "D", "A"])
    }

    @Test func applyRootOnly_MoveUp() {
        var roots = [MutableNode("A"), MutableNode("B"), MutableNode("C"), MutableNode("D")]
        let move = OutlineMove(
            sourceParentPath: nil,
            sourceIndexes: IndexSet([3]),
            destinationParentPath: nil,
            destinationIndex: 0,
            isDropOnItem: false
        )
        move.apply(to: &roots) { $0.children = $1 }
        #expect(ids(roots) == ["D", "A", "B", "C"])
    }

    // MARK: - Cross-parent regression: root → non-root, source BEFORE destination

    /// Regression test for the apply() bug where `set(_, at: destinationParentPath)`
    /// was looking up the destination parent in the *already mutated* roots tree.
    /// With `sourceIndexes=[0]` and `destinationParentPath=[3]`, the source removal
    /// shifts the destination from root[3] to root[2] in the mutated array, so the
    /// path-based lookup either returns the wrong node or falls out of bounds and
    /// the moved item silently disappears.
    @Test func applyCrossParent_RootToNonRoot_SourceBeforeDestinationInRoot() {
        let group = MutableNode("Group", children: [MutableNode("X")])
        var roots = [
            MutableNode("F1"),
            MutableNode("F2"),
            MutableNode("F3"),
            group,
        ]
        let move = OutlineMove(
            sourceParentPath: nil,
            sourceIndexes: IndexSet([0]),
            destinationParentPath: IndexPath(indexes: [3]),
            destinationIndex: 0,
            isDropOnItem: false
        )
        move.apply(to: &roots) { $0.children = $1 }
        #expect(ids(roots) == ["F2", "F3", "Group"])
        #expect(ids(group.children) == ["F1", "X"])
    }

    /// The complementary case: source AFTER destination in root means no shift,
    /// the original implementation already worked here. Pinned to make sure the
    /// fix doesn't regress it.
    @Test func applyCrossParent_RootToNonRoot_SourceAfterDestinationInRoot() {
        let group = MutableNode("Group", children: [MutableNode("X")])
        var roots = [
            group,
            MutableNode("F1"),
            MutableNode("F2"),
            MutableNode("F3"),
        ]
        let move = OutlineMove(
            sourceParentPath: nil,
            sourceIndexes: IndexSet([3]),
            destinationParentPath: IndexPath(indexes: [0]),
            destinationIndex: 1,
            isDropOnItem: false
        )
        move.apply(to: &roots) { $0.children = $1 }
        #expect(ids(roots) == ["Group", "F1", "F2"])
        #expect(ids(group.children) == ["X", "F3"])
    }

    // MARK: - Cross-parent regression: nested same-grandparent

    /// Source and destination share a common parent at root[0]. After source
    /// removal at root[0].children[0], destination at root[0].children[2] would
    /// shift to [0].children[1] in the mutated tree, so a stale path lookup
    /// finds the wrong sibling.
    @Test func applyCrossParent_NestedSameGrandparent_SourceBeforeDestination() {
        let srcChild = MutableNode("S", children: [MutableNode("S0")])
        let dstChild = MutableNode("D", children: [])
        let other = MutableNode("O", children: [])
        let parent = MutableNode("P", children: [srcChild, other, dstChild])
        var roots = [parent]

        let move = OutlineMove(
            sourceParentPath: IndexPath(indexes: [0, 0]),
            sourceIndexes: IndexSet([0]),
            destinationParentPath: IndexPath(indexes: [0, 2]),
            destinationIndex: 0,
            isDropOnItem: false
        )
        move.apply(to: &roots) { $0.children = $1 }
        #expect(ids(srcChild.children) == [])
        #expect(ids(dstChild.children) == ["S0"])
        #expect(ids(other.children) == [])
    }

    @Test func applyDropOnItem() {
        let group = MutableNode("G", children: [MutableNode("A"), MutableNode("B")])
        var roots = [MutableNode("F"), group]
        let move = OutlineMove(
            sourceParentPath: nil,
            sourceIndexes: IndexSet([0]),
            destinationParentPath: IndexPath(indexes: [1]),
            destinationIndex: NSOutlineViewDropOnItemIndex,
            isDropOnItem: true
        )
        // For a drop-on-item, acceptDrop sets dropTargetIndex = currentChildren.count,
        // so we replicate that here for the apply call (apply doesn't know about NSOutlineView).
        let normalizedMove = OutlineMove(
            sourceParentPath: move.sourceParentPath,
            sourceIndexes: move.sourceIndexes,
            destinationParentPath: move.destinationParentPath,
            destinationIndex: group.children.count,
            isDropOnItem: true
        )
        normalizedMove.apply(to: &roots) { $0.children = $1 }
        #expect(ids(roots) == ["G"])
        #expect(ids(group.children) == ["A", "B", "F"])
    }
}

/// Exercises `ReorderableOutlineViewAdapter.applyDragMove` directly against a
/// real `NSOutlineView`, simulating what the Rx binder does after `acceptDrop:`
/// has mutated the model. Tests that the view's row/parent/childIndex mapping
/// reflects the post-move tree, that the destination auto-expands when needed,
/// and that multi-item moves index-translate correctly.
@MainActor
@Suite("ApplyDragMove")
final class ApplyDragMoveTests {
    private let window: NSWindow
    private let outlineView: NSOutlineView

    init() {
        let outlineView = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        column.width = 180
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
        scrollView.documentView = outlineView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)

        self.outlineView = outlineView
        self.window = window
    }

    private func makeAdapter() -> ReorderableOutlineViewAdapter<MutableNode> {
        let adapter = ReorderableOutlineViewAdapter<MutableNode>(
            cellViewProvider: { _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func loadInitial(_ adapter: ReorderableOutlineViewAdapter<MutableNode>, _ nodes: [MutableNode]) {
        adapter.nodes = nodes
        outlineView.reloadData()
    }

    private func makePending(
        sourceParent: MutableNode? = nil,
        sortedSourceChildIndexes: [Int],
        destinationParent: MutableNode? = nil,
        baseInsertionIndex: Int,
        isSameParent: Bool
    ) -> ReorderableOutlineViewAdapter<MutableNode>.PendingDragOperation {
        ReorderableOutlineViewAdapter<MutableNode>.PendingDragOperation(
            sourceParent: sourceParent,
            sortedSourceChildIndexes: sortedSourceChildIndexes,
            destinationParent: destinationParent,
            baseInsertionIndex: baseInsertionIndex,
            isSameParent: isSameParent
        )
    }

    private func rowIDs() -> [String] {
        (0..<outlineView.numberOfRows).compactMap {
            (outlineView.item(atRow: $0) as? MutableNode)?.id
        }
    }

    // MARK: - Auto-expand on drop

    /// Drop onto a previously empty (and therefore non-expandable) group must
    /// auto-expand it after the move so the dropped item becomes visible.
    /// Without `reloadItem(_:)` first, `expandItem(_:)` is a no-op because
    /// `NSOutlineView` has cached `isItemExpandable=false` for the now-changed
    /// destination.
    @Test func dropOnCollapsedEmptyGroup_autoExpandsDestination() {
        let adapter = makeAdapter()
        let groupG = MutableNode("G")
        let leafL = MutableNode("L")
        loadInitial(adapter, [groupG, leafL])
        #expect(outlineView.numberOfRows == 2)
        #expect(!outlineView.isItemExpanded(groupG))

        // Pretend acceptDrop happened: model is now post-move.
        groupG.children = [leafL]
        adapter.nodes = [groupG]
        let pending = makePending(
            sortedSourceChildIndexes: [1],
            destinationParent: groupG,
            baseInsertionIndex: 0,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(outlineView.isItemExpanded(groupG))
        #expect(outlineView.numberOfRows == 2) // groupG + leafL
        #expect(outlineView.parent(forItem: leafL) as? MutableNode === groupG)
        #expect(outlineView.childIndex(forItem: leafL) == 0)
    }

    /// Drop onto a group that is already expanded should not toggle expansion
    /// state. The view should reflect the new child without flicker.
    @Test func dropOnExpandedGroup_keepsExpandedAndUpdatesMapping() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let groupG = MutableNode("G", children: [nodeA])
        let leafL = MutableNode("L")
        loadInitial(adapter, [groupG, leafL])
        outlineView.expandItem(groupG)
        #expect(outlineView.numberOfRows == 3) // G, A, L
        #expect(outlineView.isItemExpanded(groupG))

        groupG.children = [nodeA, leafL]
        adapter.nodes = [groupG]
        let pending = makePending(
            sortedSourceChildIndexes: [1],
            destinationParent: groupG,
            baseInsertionIndex: 1,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(outlineView.isItemExpanded(groupG))
        #expect(outlineView.numberOfRows == 3) // G, A, L
        #expect(outlineView.parent(forItem: leafL) as? MutableNode === groupG)
        #expect(outlineView.childIndex(forItem: leafL) == 1)
    }

    /// Drop to root level (`destinationParent == nil`) should not call
    /// `expandItem` on anything — there is no "destination parent" to expand.
    @Test func dropToRoot_skipsExpand() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let groupG = MutableNode("G", children: [nodeA])
        loadInitial(adapter, [groupG])
        outlineView.expandItem(groupG)
        #expect(outlineView.numberOfRows == 2) // G, A

        groupG.children = []
        adapter.nodes = [groupG, nodeA]
        let pending = makePending(
            sourceParent: groupG,
            sortedSourceChildIndexes: [0],
            destinationParent: nil,
            baseInsertionIndex: 1,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(outlineView.parent(forItem: nodeA) == nil)
        #expect(outlineView.childIndex(forItem: nodeA) == 1)
        #expect(rowIDs() == ["G", "A"])
    }

    /// Setting `expandsDropDestination = false` must leave a collapsed
    /// destination collapsed, even when dropping onto it. The drop itself
    /// still has to land correctly on the model side.
    @Test func expandsDropDestinationFalse_keepsCollapsed() {
        let adapter = makeAdapter()
        adapter.expandsDropDestination = false
        let groupG = MutableNode("G")
        let leafL = MutableNode("L")
        loadInitial(adapter, [groupG, leafL])
        #expect(!outlineView.isItemExpanded(groupG))

        groupG.children = [leafL]
        adapter.nodes = [groupG]
        let pending = makePending(
            sortedSourceChildIndexes: [1],
            destinationParent: groupG,
            baseInsertionIndex: 0,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(!outlineView.isItemExpanded(groupG))
        #expect(outlineView.numberOfRows == 1) // only G visible
    }

    // MARK: - Cross-parent move row mapping (regression)

    /// Regression: after a cross-parent drag, `NSOutlineView`'s child-index
    /// mapping for the moved item must reflect the new parent. This was the
    /// original failure mode — `StagedChangeset` could only emit per-array
    /// inserts/removes, leaving the view's internal item-to-row cache stale,
    /// so the next `willBeginAt` reported an outdated `childIndex` and the
    /// subsequent drag landed in the wrong place.
    @Test func crossParentMove_viewMappingReflectsNewParent() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let nodeB = MutableNode("B")
        let groupG1 = MutableNode("G1", children: [nodeA])
        let groupG2 = MutableNode("G2", children: [nodeB])
        loadInitial(adapter, [groupG1, groupG2])
        outlineView.expandItem(groupG1)
        outlineView.expandItem(groupG2)
        #expect(outlineView.numberOfRows == 4) // G1, A, G2, B

        // acceptDrop on G2 (drop-on-item, dropTargetIndex = G2.children.count = 1).
        groupG1.children = []
        groupG2.children = [nodeB, nodeA]
        adapter.nodes = [groupG1, groupG2]
        let pending = makePending(
            sourceParent: groupG1,
            sortedSourceChildIndexes: [0],
            destinationParent: groupG2,
            baseInsertionIndex: 1,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(outlineView.parent(forItem: nodeA) as? MutableNode === groupG2)
        #expect(outlineView.childIndex(forItem: nodeA) == 1)
        #expect(outlineView.numberOfChildren(ofItem: groupG1) == 0)
        #expect(outlineView.numberOfChildren(ofItem: groupG2) == 2)
    }

    // MARK: - Same-parent moves

    @Test func sameParentSingleItemMove() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let nodeB = MutableNode("B")
        let nodeC = MutableNode("C")
        let nodeD = MutableNode("D")
        loadInitial(adapter, [nodeA, nodeB, nodeC, nodeD])

        // Move A (idx 0) to root[3] → final [B, C, D, A], A at final idx 3.
        adapter.nodes = [nodeB, nodeC, nodeD, nodeA]
        let pending = makePending(
            sortedSourceChildIndexes: [0],
            baseInsertionIndex: 3,
            isSameParent: true
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(rowIDs() == ["B", "C", "D", "A"])
        #expect(outlineView.childIndex(forItem: nodeA) == 3)
    }

    /// Multi-item same-parent move. `acceptDrop` adjusts the insertion index
    /// to 3 (5 - 2 sources removed), giving final state `[B, D, E, A, C]`
    /// with A at idx 3 and C at idx 4. `applyDragMove` iterates descending
    /// so the larger source index is processed first and the smaller one
    /// isn't disturbed.
    @Test func sameParentMultiItemMove() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let nodeB = MutableNode("B")
        let nodeC = MutableNode("C")
        let nodeD = MutableNode("D")
        let nodeE = MutableNode("E")
        loadInitial(adapter, [nodeA, nodeB, nodeC, nodeD, nodeE])

        adapter.nodes = [nodeB, nodeD, nodeE, nodeA, nodeC]
        let pending = makePending(
            sortedSourceChildIndexes: [0, 2],
            baseInsertionIndex: 3,
            isSameParent: true
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(rowIDs() == ["B", "D", "E", "A", "C"])
        #expect(outlineView.childIndex(forItem: nodeA) == 3)
        #expect(outlineView.childIndex(forItem: nodeC) == 4)
    }

    /// Multi-item cross-parent move. After i moves the source has lost i
    /// items (live src = original - i) and the destination has gained i
    /// items (live dst = base + i). Pin both child indices in the destination.
    @Test func crossParentMultiItemMove() {
        let adapter = makeAdapter()
        let nodeA = MutableNode("A")
        let nodeB = MutableNode("B")
        let nodeC = MutableNode("C")
        let nodeD = MutableNode("D")
        let groupG1 = MutableNode("G1", children: [nodeA, nodeB, nodeC, nodeD])
        let groupG2 = MutableNode("G2") // empty
        loadInitial(adapter, [groupG1, groupG2])
        outlineView.expandItem(groupG1)

        // Move [A(0), C(2)] from G1 onto empty G2 (drop-on-item, base=0).
        groupG1.children = [nodeB, nodeD]
        groupG2.children = [nodeA, nodeC]
        adapter.nodes = [groupG1, groupG2]
        let pending = makePending(
            sourceParent: groupG1,
            sortedSourceChildIndexes: [0, 2],
            destinationParent: groupG2,
            baseInsertionIndex: 0,
            isSameParent: false
        )
        adapter.applyDragMove(pending, to: outlineView)

        #expect(outlineView.parent(forItem: nodeA) as? MutableNode === groupG2)
        #expect(outlineView.parent(forItem: nodeC) as? MutableNode === groupG2)
        #expect(outlineView.childIndex(forItem: nodeA) == 0)
        #expect(outlineView.childIndex(forItem: nodeC) == 1)
        #expect(outlineView.numberOfChildren(ofItem: groupG1) == 2)
        #expect(outlineView.numberOfChildren(ofItem: groupG2) == 2)
    }
}

// MARK: - Sectioned test models

private struct SectionHeaderModel: Differentiable, Hashable {
    let id: String
    init(_ id: String) { self.id = id }
    var differenceIdentifier: String { id }
    func isContentEqual(to source: SectionHeaderModel) -> Bool { id == source.id }
}

private struct SectionItemModel: Differentiable, Hashable {
    let id: String
    init(_ id: String) { self.id = id }
    var differenceIdentifier: String { id }
    func isContentEqual(to source: SectionItemModel) -> Bool { id == source.id }
}

@MainActor
@Suite("RxNSTableViewSectionedReloadAdapter")
final class RxNSTableViewSectionedReloadAdapterTests {
    private let tableView: NSTableView

    init() {
        let tableView = NSTableView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        column.width = 180
        tableView.addTableColumn(column)
        self.tableView = tableView
    }

    private func makeAdapter() -> RxNSTableViewSectionedReloadAdapter<SectionHeaderModel, SectionItemModel> {
        let adapter = RxNSTableViewSectionedReloadAdapter<SectionHeaderModel, SectionItemModel>(
            headerViewProvider: { _, _, _ in NSTableCellView() },
            cellViewProvider: { _, _, _, _ in NSTableCellView() }
        )
        tableView.dataSource = adapter
        tableView.delegate = adapter
        return adapter
    }

    private func section(_ id: String, _ items: [String]) -> ArraySection<SectionHeaderModel, SectionItemModel> {
        ArraySection(model: SectionHeaderModel(id), elements: items.map(SectionItemModel.init))
    }

    @Test func flattensHeaderAndItemRowsIntoLinearStream() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([
            section("S1", ["a", "b"]),
            section("S2", ["c"]),
        ]))
        // 2 section headers + 3 items
        #expect(tableView.numberOfRows == 5)
        let groupFlags = (0..<tableView.numberOfRows).map { adapter.tableView(tableView, isGroupRow: $0) }
        #expect(groupFlags == [true, false, false, true, false])
    }

    @Test func modelAtReturnsHeaderOrItem() throws {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([section("S1", ["a", "b"])]))
        #expect((try adapter.model(at: 0) as? SectionHeaderModel)?.id == "S1")
        #expect((try adapter.model(at: 1) as? SectionItemModel)?.id == "a")
        #expect((try adapter.model(at: 2) as? SectionItemModel)?.id == "b")
    }

    @Test func reloadReplacesSections() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([section("S1", ["a", "b"])]))
        #expect(tableView.numberOfRows == 3)
        adapter.tableView(tableView, observedEvent: .next([
            section("S1", ["a"]),
            section("S2", ["c", "d"]),
        ]))
        #expect(tableView.numberOfRows == 5)
        let groupFlags = (0..<tableView.numberOfRows).map { adapter.tableView(tableView, isGroupRow: $0) }
        #expect(groupFlags == [true, false, true, false, false])
    }

    @Test func proxyForwardsIsGroupRow() {
        // Bind through the real proxy chain to verify the delegate proxy actually
        // advertises and forwards `isGroupRow` (guards the @objc inference trap).
        let disposable = tableView.rx.sections(Observable.just([section("S1", ["a", "b"])]))(
            { _, _, _ in NSTableCellView() },
            { _, _, _, _ in NSTableCellView() }
        )
        defer { disposable.dispose() }
        let delegate = tableView.delegate
        #expect(delegate?.responds(to: #selector(NSTableViewDelegate.tableView(_:isGroupRow:))) == true)
        #expect(delegate?.tableView?(tableView, isGroupRow: 0) == true)
        #expect(delegate?.tableView?(tableView, isGroupRow: 1) == false)
    }
}

@MainActor
@Suite("RxNSOutlineViewSectionedAdapter")
final class RxNSOutlineViewSectionedAdapterTests {
    private let window: NSWindow
    private let outlineView: NSOutlineView

    init() {
        let outlineView = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
        column.width = 180
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        scrollView.documentView = outlineView

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 400),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = scrollView
        window.makeKeyAndOrderFront(nil)

        self.outlineView = outlineView
        self.window = window
    }

    private func makeAdapter(options: RxNSOutlineViewAdapterOptions = []) -> RxNSOutlineViewSectionedAdapter<SectionHeaderModel, TestNode> {
        let adapter = RxNSOutlineViewSectionedAdapter<SectionHeaderModel, TestNode>(
            options: options,
            sectionHeaderViewProvider: { _, _, _ in NSTableCellView() },
            cellViewProvider: { _, _, _ in NSTableCellView() }
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func section(_ id: String, _ nodes: [TestNode]) -> ArraySection<SectionHeaderModel, TestNode> {
        ArraySection(model: SectionHeaderModel(id), elements: nodes)
    }

    @Test func topLevelItemsAreSectionGroupItems() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            section("S1", [TestNode("a"), TestNode("b")]),
            section("S2", [TestNode("c")]),
        ]))
        // Two collapsed sections at the root.
        #expect(outlineView.numberOfRows == 2)
        for row in 0..<outlineView.numberOfRows {
            #expect(adapter.outlineView(outlineView, isGroupItem: outlineView.item(atRow: row) as Any) == true)
        }
    }

    @Test func expandingSectionRevealsChildNodes() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            section("S1", [TestNode("a"), TestNode("b")]),
        ]))
        outlineView.expandItem(outlineView.item(atRow: 0))
        #expect(outlineView.numberOfRows == 3) // header + a + b
        #expect(adapter.outlineView(outlineView, isGroupItem: outlineView.item(atRow: 1) as Any) == false)
        #expect(adapter.outlineView(outlineView, isGroupItem: outlineView.item(atRow: 2) as Any) == false)
    }

    @Test func childNodesKeepTheirOwnHierarchy() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            section("S1", [TestNode("Parent", children: [TestNode("A"), TestNode("B")])]),
        ]))
        outlineView.expandItem(outlineView.item(atRow: 0)) // expand section S1
        outlineView.expandItem(outlineView.item(atRow: 1)) // expand child "Parent"
        #expect(outlineView.numberOfRows == 4) // S1, Parent, A, B
    }

    @Test func proxyForwardsIsGroupItem() {
        // Bind through the real proxy chain to verify the delegate proxy actually
        // advertises and forwards `isGroupItem` (guards the @objc inference trap).
        let disposable = outlineView.rx.sections(source: Observable.just([section("S1", [TestNode("a")])]))(
            { _, _, _ in NSTableCellView() },
            { _, _, _ in NSTableCellView() }
        )
        defer { disposable.dispose() }
        let delegate = outlineView.delegate
        #expect(delegate?.responds(to: #selector(NSOutlineViewDelegate.outlineView(_:isGroupItem:))) == true)
        #expect(delegate?.outlineView?(outlineView, isGroupItem: outlineView.item(atRow: 0) as Any) == true)
    }
}
