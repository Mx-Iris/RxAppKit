import AppKit
import DifferenceKit
import RxSwift
import Testing
@testable import RxAppKit

private struct ReorderItem: Differentiable, Hashable {
    let id: String
    init(_ id: String) { self.id = id }
    var differenceIdentifier: String { id }
    func isContentEqual(to source: ReorderItem) -> Bool { id == source.id }
}

/// `acceptDrop` never reads its `NSDraggingInfo`, but the signature demands one and
/// AppKit provides no way to obtain a real instance outside a live drag. This stub
/// exists purely to satisfy the parameter.
private final class StubDraggingInfo: NSObject, NSDraggingInfo {
    var draggingDestinationWindow: NSWindow? { nil }
    var draggingSourceOperationMask: NSDragOperation { .move }
    var draggingLocation: NSPoint { .zero }
    var draggedImageLocation: NSPoint { .zero }
    var draggingPasteboard: NSPasteboard { NSPasteboard(name: .drag) }
    var draggingSource: Any? { nil }
    var draggingSequenceNumber: Int { 0 }
    var animatesToDestination: Bool = false
    var numberOfValidItemsForDrop: Int = 1
    var draggingFormation: NSDraggingFormation = .default
    var springLoadingHighlight: NSSpringLoadingHighlight { .none }

    func resetSpringLoading() {}

    func enumerateDraggingItems(
        options enumOpts: NSDraggingItemEnumerationOptions,
        for view: NSView?,
        classes classArray: [AnyClass],
        searchOptions: [NSPasteboard.ReadingOptionKey: Any],
        using block: @escaping (NSDraggingItem, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {}

    @available(macOS, deprecated: 10.14)
    var draggedImage: NSImage? { nil }

    @available(macOS, deprecated: 10.14)
    func slideDraggedImage(to screenPoint: NSPoint) {}
}

/// Drives `acceptDrop` directly, which is what AppKit calls once a drop is committed.
/// The index arithmetic inside it is the part worth pinning: the destination row is
/// expressed in pre-removal coordinates, so every dragged row above it shifts the
/// insertion point down by one.
@MainActor
@Suite("TableView drag reordering")
final class TableViewReorderTests {
    private let tableView: NSTableView
    private let window: NSWindow

    init() {
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

        self.tableView = tableView
        self.window = window
    }

    private func makeAdapter(options: RxNSTableViewAdapterOptions) -> RxNSTableViewAdapter<ReorderItem> {
        let adapter = RxNSTableViewAdapter<ReorderItem>(
            options: options,
            cellViewProvider: { _, _, _, _ in NSTableCellView() },
            rowViewProvider: nil
        )
        tableView.dataSource = adapter
        tableView.delegate = adapter
        return adapter
    }

    /// Stages a drag of `rows` and drops it above `destinationRow`, the same pair of
    /// calls AppKit makes.
    @discardableResult
    private func drag(
        _ adapter: RxNSTableViewAdapter<ReorderItem>,
        rows: IndexSet,
        above destinationRow: Int
    ) -> Bool {
        adapter.draggingRowIndexes = rows
        return adapter.tableView(
            tableView,
            acceptDrop: StubDraggingInfo(),
            row: destinationRow,
            dropOperation: .above
        )
    }

    private func visibleIDs(_ adapter: RxNSTableViewAdapter<ReorderItem>) -> [String] {
        (0 ..< tableView.numberOfRows).compactMap { (try? adapter.model(at: $0) as? ReorderItem)?.id }
    }

    private func load(_ adapter: RxNSTableViewAdapter<ReorderItem>, _ ids: [String]) {
        adapter.tableView(tableView, observedEvent: .next(ids.map(ReorderItem.init)))
    }

    // MARK: - Index arithmetic

    /// Dragging downwards: the destination is given in pre-removal coordinates, so
    /// moving "a" to row 3 of [a, b, c, d] lands it between c and d, not after d.
    @Test func draggingASingleRowDownwardsLandsBeforeTheDestination() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c", "d"])
        #expect(drag(adapter, rows: IndexSet([0]), above: 3))
        #expect(visibleIDs(adapter) == ["b", "c", "a", "d"])
    }

    /// Dragging upwards needs no correction, because no removed row sits above the
    /// destination.
    @Test func draggingASingleRowUpwardsLandsAtTheDestination() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c", "d"])
        #expect(drag(adapter, rows: IndexSet([3]), above: 0))
        #expect(visibleIDs(adapter) == ["d", "a", "b", "c"])
    }

    /// Two rows dragged together keep their relative order and both shift the
    /// insertion point.
    @Test func draggingTwoAdjacentRowsToTheEndKeepsTheirOrder() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c", "d"])
        #expect(drag(adapter, rows: IndexSet([0, 1]), above: 4))
        #expect(visibleIDs(adapter) == ["c", "d", "a", "b"])
    }

    /// A non-contiguous selection collapses into a contiguous block at the destination.
    @Test func draggingNonAdjacentRowsCollapsesThemTogether() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c", "d", "e"])
        #expect(drag(adapter, rows: IndexSet([0, 2]), above: 5))
        #expect(visibleIDs(adapter) == ["b", "d", "e", "a", "c"])
    }

    @Test func droppingARowOntoItsOwnPositionChangesNothing() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])
        #expect(drag(adapter, rows: IndexSet([1]), above: 1))
        #expect(visibleIDs(adapter) == ["a", "b", "c"])
    }

    // MARK: - Commit strategies

    /// Reload mode is self-contained: the drop commits to `items` straight away, so
    /// the view is correct without the caller routing `modelMoved` back upstream.
    @Test func reloadModeCommitsTheNewOrderImmediately() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])
        drag(adapter, rows: IndexSet([2]), above: 0)

        #expect(adapter.items.map(\.id) == ["c", "a", "b"])
        #expect(adapter.hasItemsOverride == false)
        #expect(visibleIDs(adapter) == ["c", "a", "b"])
    }

    /// Diffable mode stages the ordering instead: the view shows the new order right
    /// away, but the committed store waits for the bound sequence to echo it back, so
    /// the change can animate through the same pipeline as every other update.
    @Test func diffableModeStagesTheOrderWithoutCommittingIt() {
        let adapter = makeAdapter(options: [.reorderable, .diffable])
        load(adapter, ["a", "b", "c"])
        drag(adapter, rows: IndexSet([2]), above: 0)

        #expect(adapter.hasItemsOverride == true)
        #expect(adapter.items.map(\.id) == ["a", "b", "c"])
        #expect(visibleIDs(adapter) == ["c", "a", "b"])
    }

    /// Once the bound sequence emits the reordered data, the staged override is
    /// cleared and the committed store takes over.
    @Test func theStagedOrderIsClearedOnTheNextEmission() {
        let adapter = makeAdapter(options: [.reorderable, .diffable])
        load(adapter, ["a", "b", "c"])
        drag(adapter, rows: IndexSet([2]), above: 0)
        #expect(adapter.hasItemsOverride == true)

        load(adapter, ["c", "a", "b"])
        #expect(adapter.hasItemsOverride == false)
        #expect(adapter.items.map(\.id) == ["c", "a", "b"])
        #expect(visibleIDs(adapter) == ["c", "a", "b"])
    }

    /// An upstream emission that contradicts the staged drop wins — the override is
    /// dropped rather than shadowing newer data.
    @Test func anUnrelatedEmissionDiscardsTheStagedOrder() {
        let adapter = makeAdapter(options: [.reorderable, .diffable])
        load(adapter, ["a", "b", "c"])
        drag(adapter, rows: IndexSet([2]), above: 0)

        load(adapter, ["x", "y"])
        #expect(adapter.hasItemsOverride == false)
        #expect(visibleIDs(adapter) == ["x", "y"])
    }

    // MARK: - Events and gating

    @Test func acceptingADropEmitsTheMoveIndexes() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])

        var movedIndexes: [(sourceIndexes: IndexSet, destinationIndex: Int)] = []
        let disposable = adapter.itemMoved.subscribe(onNext: { movedIndexes.append($0) })
        defer { disposable.dispose() }

        drag(adapter, rows: IndexSet([0]), above: 3)
        #expect(movedIndexes.count == 1)
        #expect(movedIndexes.first?.sourceIndexes == IndexSet([0]))
        #expect(movedIndexes.first?.destinationIndex == 2)
    }

    @Test func acceptingADropEmitsTheReorderedModels() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])

        var emittedOrders: [[String]] = []
        let disposable = adapter.modelMoved.subscribe(onNext: { models in
            emittedOrders.append(models.compactMap { ($0 as? ReorderItem)?.id })
        })
        defer { disposable.dispose() }

        drag(adapter, rows: IndexSet([2]), above: 0)
        #expect(emittedOrders == [["c", "a", "b"]])
    }

    /// `didReorder` is the non-Rx escape hatch and has to see the same final ordering
    /// the subjects publish.
    @Test func theReorderingHandlerSeesTheFinalOrdering() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])

        var handlerOrders: [[String]] = []
        adapter.reorderingHandlers.didReorder = { items in
            handlerOrders.append(items.map(\.id))
        }

        drag(adapter, rows: IndexSet([0]), above: 2)
        #expect(handlerOrders == [["b", "a", "c"]])
    }

    /// A drop with nothing staged must be refused rather than reordering by accident.
    @Test func aDropWithNoStagedRowsIsRefused() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])

        let accepted = adapter.tableView(
            tableView,
            acceptDrop: StubDraggingInfo(),
            row: 0,
            dropOperation: .above
        )
        #expect(accepted == false)
        #expect(visibleIDs(adapter) == ["a", "b", "c"])
    }

    /// Staged rows are consumed by the drop, so a second drop cannot replay the first.
    @Test func stagedRowsDoNotSurviveTheDropTheyCommitted() {
        let adapter = makeAdapter(options: .reorderable)
        load(adapter, ["a", "b", "c"])
        drag(adapter, rows: IndexSet([0]), above: 3)
        #expect(visibleIDs(adapter) == ["b", "c", "a"])

        let replayed = adapter.tableView(
            tableView,
            acceptDrop: StubDraggingInfo(),
            row: 0,
            dropOperation: .above
        )
        #expect(replayed == false)
        #expect(visibleIDs(adapter) == ["b", "c", "a"])
    }
}
