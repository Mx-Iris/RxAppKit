import AppKit
import DifferenceKit
import RxSwift
import RxCocoa
import Testing
@testable import RxAppKit

private struct ProxyItem: Differentiable, Hashable {
    let id: String
    init(_ id: String) { self.id = id }
    var differenceIdentifier: String { id }
    func isContentEqual(to source: ProxyItem) -> Bool { id == source.id }
}

/// A delegate that implements none of the selectors the proxy gates on, so it can
/// show that an unimplemented optional method is *not* advertised on its behalf.
private final class PlainTableDelegate: NSObject, NSTableViewDelegate {
    var observedSelectionChanges = 0

    func tableViewSelectionDidChange(_ notification: Notification) {
        observedSelectionChanges += 1
    }
}

/// A delegate that does implement `isGroupRow`, which is the case the proxy must
/// start advertising and forwarding.
private final class GroupAwareTableDelegate: NSObject, NSTableViewDelegate {
    var groupRows: Set<Int> = []
    private(set) var queriedRows: [Int] = []

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        queriedRows.append(row)
        return groupRows.contains(row)
    }
}

@MainActor
@Suite("NSTableView delegate proxy")
final class TableViewDelegateProxyTests {
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

    private func bindItems(_ source: Observable<[ProxyItem]>) -> Disposable {
        tableView.rx.items(source)({ _, _, _, _ in NSTableCellView() })
    }

    // MARK: - Lifetime

    /// Disposing a binding has to stop the view tracking the sequence. If the
    /// subscription outlived the disposable, a later emission would still rewrite
    /// rows on a view the caller considers unbound.
    @Test func disposingABindingStopsFurtherUpdates() {
        let items = PublishSubject<[ProxyItem]>()
        let disposable = bindItems(items.asObservable())

        items.onNext([ProxyItem("a"), ProxyItem("b")])
        #expect(tableView.numberOfRows == 2)

        disposable.dispose()
        items.onNext([ProxyItem("a"), ProxyItem("b"), ProxyItem("c")])
        #expect(tableView.numberOfRows == 2)
    }

    /// Binding twice must leave exactly one live binding, with the newest sequence
    /// in charge — otherwise two adapters fight over the same data source.
    @Test func rebindingHandsControlToTheNewestSequence() {
        let first = PublishSubject<[ProxyItem]>()
        let second = PublishSubject<[ProxyItem]>()

        let firstDisposable = bindItems(first.asObservable())
        first.onNext([ProxyItem("a")])
        #expect(tableView.numberOfRows == 1)

        let secondDisposable = bindItems(second.asObservable())
        second.onNext([ProxyItem("x"), ProxyItem("y")])
        #expect(tableView.numberOfRows == 2)

        // The first sequence no longer owns the view.
        first.onNext([ProxyItem("a"), ProxyItem("b"), ProxyItem("c")])
        #expect(tableView.numberOfRows == 2)

        firstDisposable.dispose()
        secondDisposable.dispose()
    }

    /// The proxy is per-view and stable: every lookup has to return the same object,
    /// or subscriptions taken at different times would land on different proxies.
    @Test func theProxyIsTheSameObjectOnEveryLookup() {
        let first = tableView.rx.tableViewDelegate
        let second = tableView.rx.tableViewDelegate
        #expect(first === second)
    }

    // MARK: - Forwarding to a user delegate

    /// A user delegate installed alongside an Rx binding must keep receiving its own
    /// callbacks; the proxy intercepts, it does not replace.
    @Test func aUserDelegateKeepsReceivingItsOwnCallbacks() throws {
        let userDelegate = PlainTableDelegate()
        let delegateDisposable = tableView.rx.setDelegate(userDelegate)
        defer { delegateDisposable.dispose() }
        let itemsDisposable = bindItems(.just([ProxyItem("a")]))
        defer { itemsDisposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        installedDelegate.tableViewSelectionDidChange?(
            Notification(name: NSTableView.selectionDidChangeNotification, object: tableView)
        )
        #expect(userDelegate.observedSelectionChanges == 1)
    }

    /// `isGroupRow` is optional. Advertising it unconditionally would let a plain
    /// binding shadow a user delegate's own implementation, so the proxy only claims
    /// it when something downstream really implements it.
    @Test func groupRowStaysUnadvertisedForAPlainBinding() throws {
        let disposable = bindItems(.just([ProxyItem("a")]))
        defer { disposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        #expect(installedDelegate.responds(to: #selector(NSTableViewDelegate.tableView(_:isGroupRow:))) == false)
    }

    @Test func groupRowIsAdvertisedOnceAUserDelegateImplementsIt() throws {
        let userDelegate = GroupAwareTableDelegate()
        let delegateDisposable = tableView.rx.setDelegate(userDelegate)
        defer { delegateDisposable.dispose() }
        let itemsDisposable = bindItems(.just([ProxyItem("a"), ProxyItem("b")]))
        defer { itemsDisposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        #expect(installedDelegate.responds(to: #selector(NSTableViewDelegate.tableView(_:isGroupRow:))) == true)
    }

    @Test func groupRowForwardsItsAnswerFromTheUserDelegate() throws {
        let userDelegate = GroupAwareTableDelegate()
        userDelegate.groupRows = [0]
        let delegateDisposable = tableView.rx.setDelegate(userDelegate)
        defer { delegateDisposable.dispose() }
        let itemsDisposable = bindItems(.just([ProxyItem("a"), ProxyItem("b")]))
        defer { itemsDisposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        #expect(installedDelegate.tableView?(tableView, isGroupRow: 0) == true)
        #expect(installedDelegate.tableView?(tableView, isGroupRow: 1) == false)
        #expect(userDelegate.queriedRows == [0, 1])
    }

    // MARK: - Selection predicate

    /// `shouldSelectRow` vetoes rows before AppKit applies the selection. Rows the
    /// predicate rejects must be absent from the returned index set.
    @Test func theSelectionPredicateFiltersProposedRows() throws {
        let itemsDisposable = bindItems(.just([ProxyItem("a"), ProxyItem("b"), ProxyItem("c")]))
        defer { itemsDisposable.dispose() }
        let predicateDisposable = tableView.rx.shouldSelectRow { _, row, _ in row != 1 }
        defer { predicateDisposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        let accepted = installedDelegate.tableView?(
            tableView,
            selectionIndexesForProposedSelection: IndexSet([0, 1, 2])
        )
        #expect(accepted == IndexSet([0, 2]))
    }

    /// Disposing the predicate restores the unfiltered behaviour rather than leaving
    /// the last predicate installed forever.
    @Test func disposingThePredicateStopsFiltering() throws {
        let itemsDisposable = bindItems(.just([ProxyItem("a"), ProxyItem("b")]))
        defer { itemsDisposable.dispose() }

        let predicateDisposable = tableView.rx.shouldSelectRow { _, _, _ in false }
        let installedDelegate = try #require(tableView.delegate)
        #expect(installedDelegate.tableView?(tableView, selectionIndexesForProposedSelection: IndexSet([0])) == IndexSet())

        predicateDisposable.dispose()
        #expect(installedDelegate.tableView?(tableView, selectionIndexesForProposedSelection: IndexSet([0])) == IndexSet([0]))
    }

    /// The predicate must not be consulted for rows outside the table's range —
    /// a stale proposed index would otherwise index into the model out of bounds.
    @Test func outOfRangeProposedRowsAreDroppedBeforeThePredicateSeesThem() throws {
        let itemsDisposable = bindItems(.just([ProxyItem("a")]))
        defer { itemsDisposable.dispose() }

        var inspectedRows: [Int] = []
        let predicateDisposable = tableView.rx.shouldSelectRow { _, row, _ in
            inspectedRows.append(row)
            return true
        }
        defer { predicateDisposable.dispose() }

        let installedDelegate = try #require(tableView.delegate)
        let accepted = installedDelegate.tableView?(
            tableView,
            selectionIndexesForProposedSelection: IndexSet([0, 5])
        )
        #expect(accepted == IndexSet([0]))
        #expect(inspectedRows == [0])
    }
}
