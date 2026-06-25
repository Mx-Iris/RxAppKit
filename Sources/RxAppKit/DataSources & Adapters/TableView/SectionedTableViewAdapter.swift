import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

/// Base data source / delegate for a *sectioned* `NSTableView`.
///
/// `NSTableView` has no native notion of sections; a "section" is rendered by
/// flattening `[ArraySection<SectionHeader, Item>]` into a single linear stream
/// of rows — one group-header row per section followed by that section's item
/// rows — and answering `tableView(_:isGroupRow:)` for the header rows so AppKit
/// draws them as (optionally floating) group rows.
///
/// Header rows and item rows are produced by two separate providers so callers
/// never have to branch on a row's kind themselves. This adapter is neither
/// reorderable nor diffable; use `RxNSTableViewSectionedReloadAdapter` for the
/// Rx binding, which reloads on every observed event.
open class SectionedTableViewAdapter<SectionHeader: Differentiable, Item: Differentiable>:
    NSObject, NSTableViewDataSource, NSTableViewDelegate, RowsViewDataSourceType, RxNSTableViewProposedSelectionEmitting {

    public typealias Section = ArraySection<SectionHeader, Item>

    /// Builds the view for a section's group-header row. AppKit draws group rows
    /// spanning every column and usually only asks the first column, so the
    /// provider receives the section index rather than a specific column.
    public typealias HeaderViewProvider = (_ tableView: NSTableView, _ sectionIndex: Int, _ header: SectionHeader) -> NSView?

    /// Builds the view for an item row. `indexPath` is `(section, item)`.
    public typealias CellViewProvider = (_ tableView: NSTableView, _ tableColumn: NSTableColumn?, _ indexPath: IndexPath, _ item: Item) -> NSView?

    /// Builds the row view for either a header row or an item row.
    public typealias RowViewProvider = (_ tableView: NSTableView, _ row: Int, _ rowKind: RowKind) -> NSTableRowView?

    /// Identifies which logical entity a flattened row index maps to.
    public enum RowKind: Equatable {
        case sectionHeader(sectionIndex: Int)
        case item(indexPath: IndexPath)
    }

    public let headerViewProvider: HeaderViewProvider
    public let cellViewProvider: CellViewProvider
    public let rowViewProvider: RowViewProvider?

    public internal(set) var sections: [Section] = []

    /// Flattened row map rebuilt on every `setSections`. `resolvedRows[row]` is an
    /// O(1) reverse lookup from a linear row index back to its logical kind.
    private var resolvedRows: [RowKind] = []

    let _proposedSelection = PublishSubject<NSTableView.ProposedSelection>()

    public init(
        headerViewProvider: @escaping HeaderViewProvider,
        cellViewProvider: @escaping CellViewProvider,
        rowViewProvider: RowViewProvider? = nil
    ) {
        self.headerViewProvider = headerViewProvider
        self.cellViewProvider = cellViewProvider
        self.rowViewProvider = rowViewProvider
        super.init()
    }

    deinit {
        _proposedSelection.onCompleted()
    }

    open func setSections(_ sections: [Section]) {
        self.sections = sections
        var resolvedRows: [RowKind] = []
        for (sectionIndex, section) in sections.enumerated() {
            resolvedRows.append(.sectionHeader(sectionIndex: sectionIndex))
            for itemIndex in section.elements.indices {
                resolvedRows.append(.item(indexPath: IndexPath(item: itemIndex, section: sectionIndex)))
            }
        }
        self.resolvedRows = resolvedRows
    }

    // MARK: - NSTableViewDataSource

    open func numberOfRows(in tableView: NSTableView) -> Int {
        return resolvedRows.count
    }

    // MARK: - NSTableViewDelegate

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch resolvedRows[row] {
        case let .sectionHeader(sectionIndex):
            return headerViewProvider(tableView, sectionIndex, sections[sectionIndex].model)
        case let .item(indexPath):
            return cellViewProvider(tableView, tableColumn, indexPath, sections[indexPath.section].elements[indexPath.item])
        }
    }

    /// `@objc` is mandatory: `isGroupRow` is an optional `NSTableViewDelegate`
    /// method, and without it AppKit's `respondsToSelector:` check fails through
    /// the delegate proxy, so group rows silently never render.
    @objc open func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if case .sectionHeader = resolvedRows[row] { return true }
        return false
    }

    open func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return rowViewProvider?(tableView, row, resolvedRows[row])
    }

    /// AppKit invokes this only for user-driven selection changes (mouse,
    /// keyboard, type-select). Emitting here lets `Reactive.proposedSelection()`
    /// expose a clean stream without the programmatic-selection noise that
    /// `selectionDidChangeNotification` carries.
    @objc open func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        _proposedSelection.onNext(.init(indexes: proposedSelectionIndexes, triggeringEvent: tableView.window?.currentEvent))
        return proposedSelectionIndexes
    }

    // MARK: - RowsViewDataSourceType

    /// Returns the `Item` for an item row, or the `SectionHeader` for a header row.
    public func model(at row: Int) throws -> Any {
        guard row >= 0, row < resolvedRows.count else {
            throw RxDataSourceError.outOfBounds(indexPath: IndexPath(item: row, section: 0))
        }
        switch resolvedRows[row] {
        case let .sectionHeader(sectionIndex):
            return sections[sectionIndex].model
        case let .item(indexPath):
            return sections[indexPath.section].elements[indexPath.item]
        }
    }
}
