import AppKit
import DifferenceKit
import RxSwift
import Testing
@testable import RxAppKit

/// Same shape as a real node type: `==` is identity-only so the outline view keeps
/// rows expanded across updates, while `isContentEqual` walks the subtree so the
/// diffing engine can still see content changes.
private struct DiffNode: OutlineNodeType, Hashable, Differentiable {
    let id: String
    let children: [DiffNode]

    init(_ id: String, children: [DiffNode] = []) {
        self.id = id
        self.children = children
    }

    static func == (lhs: DiffNode, rhs: DiffNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var differenceIdentifier: String { id }

    func isContentEqual(to source: DiffNode) -> Bool {
        guard id == source.id, children.count == source.children.count else { return false }
        return zip(children, source.children).allSatisfy { $0.isContentEqual(to: $1) }
    }
}

@MainActor
private func makeOutlineView() -> NSOutlineView {
    let outlineView = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
    column.width = 180
    outlineView.addTableColumn(column)
    outlineView.outlineTableColumn = column
    return outlineView
}

@MainActor
private func hostInWindow(_ outlineView: NSOutlineView) -> NSWindow {
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
    return window
}

/// Covers the staged-changeset application path in `NSOutlineView+StagedChangeset`:
/// the windowless early return, multi-stage changesets, and the source/target index
/// translation a move has to go through.
@MainActor
@Suite("OutlineView staged changeset")
final class OutlineViewStagedChangesetTests {
    private let outlineView: NSOutlineView
    private let window: NSWindow

    init() {
        outlineView = makeOutlineView()
        window = hostInWindow(outlineView)
    }

    private func makeAdapter() -> RxNSOutlineViewAdapter<DiffNode> {
        let adapter = RxNSOutlineViewAdapter<DiffNode>(
            options: .diffable,
            cellViewProvider: { _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func rowIDs() -> [String] {
        (0 ..< outlineView.numberOfRows).compactMap { (outlineView.item(atRow: $0) as? DiffNode)?.id }
    }

    /// Several moves in one emission. `StagedChangeset` splits work whose indices
    /// would otherwise collide into separate stages, and every stage has to be
    /// applied in order for the final ordering to come out right.
    @Test func reversingACollectionEndsInTheTargetOrder() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c", "d", "e"].map { DiffNode($0) }
        ))
        adapter.outlineView(outlineView, observedEvent: .next(
            ["e", "d", "c", "b", "a"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["e", "d", "c", "b", "a"])
        #expect(adapter.nodes.map(\.id) == ["e", "d", "c", "b", "a"])
    }

    /// Deletes, inserts and moves arriving together — the combination that makes
    /// source-space and target-space indices disagree.
    @Test func simultaneousInsertDeleteAndMoveLandCorrectly() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c", "d"].map { DiffNode($0) }
        ))
        // b is dropped, x and y are new, and c moves ahead of a.
        adapter.outlineView(outlineView, observedEvent: .next(
            ["c", "x", "a", "y", "d"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["c", "x", "a", "y", "d"])
        #expect(adapter.nodes.map(\.id) == ["c", "x", "a", "y", "d"])
    }

    @Test func movingASingleItemToTheEndKeepsEveryOtherPosition() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c"].map { DiffNode($0) }
        ))
        adapter.outlineView(outlineView, observedEvent: .next(
            ["b", "c", "a"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["b", "c", "a"])
    }

    /// A change nested two levels down still has to surface. `isContentEqual`
    /// recurses, so the root node reports itself as updated.
    @Test func aChangeTwoLevelsDeepStillSurfaces() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            DiffNode("Root", children: [DiffNode("Mid", children: [DiffNode("Leaf")])]),
        ]))
        outlineView.expandItem(DiffNode("Root"))
        outlineView.expandItem(DiffNode("Mid"))
        #expect(rowIDs() == ["Root", "Mid", "Leaf"])

        adapter.outlineView(outlineView, observedEvent: .next([
            DiffNode("Root", children: [DiffNode("Mid", children: [DiffNode("Leaf"), DiffNode("Leaf2")])]),
        ]))
        outlineView.expandItem(DiffNode("Root"))
        outlineView.expandItem(DiffNode("Mid"))
        #expect(rowIDs() == ["Root", "Mid", "Leaf", "Leaf2"])
    }

    @Test func replacingEveryItemAtOnceLeavesNoStaleRow() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c"].map { DiffNode($0) }
        ))
        adapter.outlineView(outlineView, observedEvent: .next(
            ["x", "y"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["x", "y"])
        #expect(adapter.nodes.map(\.id) == ["x", "y"])
    }

    @Test func clearingTheCollectionEmptiesTheOutlineView() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b"].map { DiffNode($0) }
        ))
        adapter.outlineView(outlineView, observedEvent: .next([]))
        #expect(outlineView.numberOfRows == 0)
        #expect(adapter.nodes.isEmpty)
    }

    @Test func growingFromEmptyPopulatesEveryRow() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([]))
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["a", "b"])
    }
}

/// The staged-changeset extension refuses to run batch updates on an outline view
/// that has no window, because AppKit's row bookkeeping is not live then. It has to
/// fall back to `reloadData()` — and the committed data must still be the newest one,
/// not the intermediate stage it stopped at.
@MainActor
@Suite("OutlineView without a window")
final class OutlineViewWindowlessTests {
    private let outlineView = makeOutlineView()

    private func makeAdapter() -> RxNSOutlineViewAdapter<DiffNode> {
        let adapter = RxNSOutlineViewAdapter<DiffNode>(
            options: .diffable,
            cellViewProvider: { _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        outlineView.dataSource = adapter
        outlineView.delegate = adapter
        return adapter
    }

    private func rowIDs() -> [String] {
        (0 ..< outlineView.numberOfRows).compactMap { (outlineView.item(atRow: $0) as? DiffNode)?.id }
    }

    @Test func theViewHasNoWindow() {
        #expect(outlineView.window == nil)
    }

    @Test func updatesStillReachTheFinalState() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["a", "b", "c"])

        adapter.outlineView(outlineView, observedEvent: .next(
            ["c", "a", "x"].map { DiffNode($0) }
        ))
        #expect(rowIDs() == ["c", "a", "x"])
        #expect(adapter.nodes.map(\.id) == ["c", "a", "x"])
    }

    /// The committed model must be the last stage's data, not an intermediate one —
    /// the bug this guards is "the view reloaded but the adapter kept stale nodes".
    @Test func theCommittedModelMatchesWhatTheViewShows() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next(
            ["a", "b", "c", "d", "e"].map { DiffNode($0) }
        ))
        adapter.outlineView(outlineView, observedEvent: .next(
            ["e", "d", "c", "b", "a"].map { DiffNode($0) }
        ))
        #expect(adapter.nodes.map(\.id) == rowIDs())
        #expect(adapter.nodes.map(\.id) == ["e", "d", "c", "b", "a"])
    }

    @Test func subtreeChangesSurfaceWithoutAWindowToo() {
        let adapter = makeAdapter()
        adapter.outlineView(outlineView, observedEvent: .next([
            DiffNode("Parent", children: [DiffNode("A")]),
        ]))
        outlineView.expandItem(DiffNode("Parent"))
        #expect(rowIDs() == ["Parent", "A"])

        adapter.outlineView(outlineView, observedEvent: .next([
            DiffNode("Parent", children: [DiffNode("A"), DiffNode("B")]),
        ]))
        outlineView.expandItem(DiffNode("Parent"))
        #expect(rowIDs() == ["Parent", "A", "B"])
    }
}
