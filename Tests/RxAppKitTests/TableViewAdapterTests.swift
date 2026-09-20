import AppKit
import DifferenceKit
import RxSwift
import Testing
@testable import RxAppKit

/// Identity-based `==` with content carried separately, mirroring how a real model
/// type has to behave: `NSTableView` and `NSOutlineView` track rows by identity, so
/// `differenceIdentifier` is the id while `isContentEqual` is what decides whether a
/// row needs redrawing.
private struct ItemModel: Differentiable, Hashable {
    let id: String
    let title: String

    init(_ id: String, title: String = "") {
        self.id = id
        self.title = title
    }

    var differenceIdentifier: String { id }

    func isContentEqual(to source: ItemModel) -> Bool {
        id == source.id && title == source.title
    }
}

@MainActor
private func makeHostedTableView() -> (NSTableView, NSWindow) {
    let tableView = NSTableView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
    column.width = 180
    tableView.addTableColumn(column)

    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
    scrollView.documentView = tableView

    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 200, height: 400),
        styleMask: [.titled],
        backing: .buffered,
        defer: false
    )
    window.contentView = scrollView
    window.makeKeyAndOrderFront(nil)
    return (tableView, window)
}

@MainActor
@Suite("RxNSTableViewAnimatedAdapter")
final class RxNSTableViewAnimatedAdapterTests {
    private let tableView: NSTableView
    private let window: NSWindow

    init() {
        (tableView, window) = makeHostedTableView()
    }

    private func makeAdapter(
        decideViewTransition: @escaping RxNSTableViewAnimatedAdapter<ItemModel>.DecideViewTransition = { _, _, _ in .animated }
    ) -> RxNSTableViewAnimatedAdapter<ItemModel> {
        let adapter = RxNSTableViewAnimatedAdapter<ItemModel>(
            animationConfiguration: TableViewAnimationConfiguration(),
            decideViewTransition: decideViewTransition,
            cellViewProvider: { _, _, _, _ in NSTableCellView() },
            rowViewProvider: { _, _, _ in NSTableRowView() }
        )
        tableView.dataSource = adapter
        tableView.delegate = adapter
        return adapter
    }

    private func rowIDs(_ adapter: RxNSTableViewAnimatedAdapter<ItemModel>) -> [String] {
        (0 ..< tableView.numberOfRows).compactMap { (try? adapter.model(at: $0) as? ItemModel)?.id }
    }

    @Test func firstEmissionPopulatesEveryRow() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b")]))
        #expect(tableView.numberOfRows == 2)
        #expect(rowIDs(adapter) == ["a", "b"])
    }

    @Test func insertionLandsAtItsDiffedPosition() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("c")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b"), ItemModel("c")]))
        #expect(rowIDs(adapter) == ["a", "b", "c"])
    }

    @Test func deletionRemovesOnlyTheMissingRow() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b"), ItemModel("c")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("c")]))
        #expect(rowIDs(adapter) == ["a", "c"])
    }

    /// A move is the case the index translation in DifferenceKit's table-view
    /// extension exists for: source and target offsets are expressed against
    /// different coordinate spaces.
    @Test func reorderingProducesTheTargetOrder() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b"), ItemModel("c")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("c"), ItemModel("a"), ItemModel("b")]))
        #expect(rowIDs(adapter) == ["c", "a", "b"])
    }

    @Test func insertionCombinedWithAMoveKeepsBothPositions() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b"), ItemModel("c")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("c"), ItemModel("x"), ItemModel("a"), ItemModel("b")]))
        #expect(rowIDs(adapter) == ["c", "x", "a", "b"])
    }

    /// A content-only change (same ids, different payload) must still reach the
    /// table: it is a reload of that row, not an insert or a delete.
    @Test func contentOnlyChangeKeepsIdentityAndUpdatesTheModel() throws {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a", title: "before")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a", title: "after")]))
        #expect(tableView.numberOfRows == 1)
        #expect((try adapter.model(at: 0) as? ItemModel)?.title == "after")
    }

    /// `decideViewTransition` returning `.reload` is the caller's escape hatch for
    /// changesets too large to animate. The final state must be identical either way.
    @Test func reloadTransitionReachesTheSameFinalState() {
        let adapter = makeAdapter(decideViewTransition: { _, _, _ in .reload })
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b")]))
        let replacement = (0 ..< 6).map { ItemModel("n\($0)") }
        adapter.tableView(tableView, observedEvent: .next(replacement))
        #expect(rowIDs(adapter) == replacement.map(\.id))
    }

    @Test func emittingAnEmptyCollectionClearsEveryRow() {
        let adapter = makeAdapter()
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b")]))
        adapter.tableView(tableView, observedEvent: .next([]))
        #expect(tableView.numberOfRows == 0)
    }
}

@MainActor
@Suite("RxNSTableViewAdapter options")
final class RxNSTableViewAdapterOptionsTests {
    private let tableView: NSTableView
    private let window: NSWindow

    init() {
        (tableView, window) = makeHostedTableView()
    }

    private func makeAdapter(options: RxNSTableViewAdapterOptions) -> RxNSTableViewAdapter<ItemModel> {
        let adapter = RxNSTableViewAdapter<ItemModel>(
            options: options,
            cellViewProvider: { _, _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        tableView.dataSource = adapter
        tableView.delegate = adapter
        return adapter
    }

    private func rowIDs(_ adapter: RxNSTableViewAdapter<ItemModel>) -> [String] {
        (0 ..< tableView.numberOfRows).compactMap { (try? adapter.model(at: $0) as? ItemModel)?.id }
    }

    @Test func diffableOptionAppliesAnIncrementalUpdate() {
        let adapter = makeAdapter(options: .diffable)
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("b"), ItemModel("a"), ItemModel("c")]))
        #expect(rowIDs(adapter) == ["b", "a", "c"])
    }

    @Test func defaultOptionsReplaceTheDataWholesale() {
        let adapter = makeAdapter(options: [])
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a"), ItemModel("b")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("c")]))
        #expect(rowIDs(adapter) == ["c"])
    }

    /// Re-emitting an identical collection is a no-op for the diffable path: the
    /// changeset is empty and nothing should be touched.
    @Test func reemittingIdenticalDataLeavesTheRowsAlone() {
        let adapter = makeAdapter(options: .diffable)
        let items = [ItemModel("a"), ItemModel("b")]
        adapter.tableView(tableView, observedEvent: .next(items))
        adapter.tableView(tableView, observedEvent: .next(items))
        #expect(rowIDs(adapter) == ["a", "b"])
    }

    /// Identity survives a content-only change, so the diffable path must report a
    /// reload rather than a delete + insert pair.
    @Test func diffableContentOnlyChangeUpdatesTheModelInPlace() throws {
        let adapter = makeAdapter(options: .diffable)
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a", title: "before"), ItemModel("b")]))
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a", title: "after"), ItemModel("b")]))
        #expect(tableView.numberOfRows == 2)
        #expect((try adapter.model(at: 0) as? ItemModel)?.title == "after")
    }

    /// The reorder commit strategy is picked from the options at init time: diffable
    /// drops animate through the binding round-trip, reload drops commit in place.
    @Test func commitStrategyFollowsTheDiffableOption() {
        #expect(makeAdapter(options: .diffable).reorderCommitStrategy == .deferredToBinding)
        #expect(makeAdapter(options: []).reorderCommitStrategy == .immediate)
        #expect(makeAdapter(options: [.diffable, .reorderable]).reorderCommitStrategy == .deferredToBinding)
        #expect(makeAdapter(options: .reorderable).reorderCommitStrategy == .immediate)
    }

    /// Reordering is off unless asked for, so a plain binding cannot start a drag.
    @Test func reorderingStaysOffWithoutTheReorderableOption() {
        #expect(makeAdapter(options: []).isReorderingEnabled == false)
        #expect(makeAdapter(options: .diffable).isReorderingEnabled == false)
        #expect(makeAdapter(options: .reorderable).isReorderingEnabled == true)
    }

    /// `pasteboardWriterForRow` is the gate AppKit asks before starting a drag;
    /// it must stay shut while reordering is disabled.
    @Test func dragIsRefusedWhileReorderingIsDisabled() {
        let adapter = makeAdapter(options: [])
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a")]))
        #expect(adapter.tableView(tableView, pasteboardWriterForRow: 0) == nil)
    }

    @Test func dragIsOfferedWhenReorderingIsEnabled() {
        let adapter = makeAdapter(options: .reorderable)
        adapter.tableView(tableView, observedEvent: .next([ItemModel("a")]))
        #expect(adapter.tableView(tableView, pasteboardWriterForRow: 0) != nil)
    }
}
