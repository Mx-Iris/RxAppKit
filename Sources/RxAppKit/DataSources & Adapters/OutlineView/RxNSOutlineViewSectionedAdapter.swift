import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

/// Rx data source / delegate adapter for a *sectioned* `NSOutlineView`. Top-level
/// items are section headers (rendered as group items via
/// `outlineView(_:isGroupItem:)`); each section's elements are child nodes that
/// may themselves be trees. Bind an
/// `Observable<[ArraySection<SectionHeader, ChildNode>]>` (or the friendlier
/// `[OutlineViewSection<SectionHeader, ChildNode>]` alias).
///
/// Unlike the homogeneous `RxNSOutlineViewAdapter`, this adapter vends the *real*
/// `SectionHeader` and `ChildNode` model objects directly as the outline view's
/// items — it does **not** wrap them in a private bridge type. That keeps the
/// whole item-based AppKit surface working transparently for callers:
/// `outlineView.item(atRow:)` (hence `rx.modelSelected()` / `rx.modelClicked()`),
/// `row(forItem:)`, `expandItem(_:)`, `reloadItem(_:reloadChildren:)`,
/// `isItemExpanded(_:)` and `itemAtClickedRow` all return / accept the same
/// `ChildNode` (or `SectionHeader`) instances the caller bound — no translation
/// shims required.
///
/// `NSOutlineView` has no section-level batch-update API, so updates always go
/// through `reloadData()` (mirroring `RxNSTableViewSectionedReloadAdapter`). The
/// `options` value is accepted for call-site symmetry with the homogeneous
/// adapters but the diffable / reorderable behaviors are intentionally not
/// supported for sectioned outlines yet.
///
/// Declared `internal` rather than `public`/`open`: callers drive it through
/// `rx.sections(...)`, which constructs it internally and returns only a
/// `Disposable`, so the type never appears in any public signature.
final class RxNSOutlineViewSectionedAdapter<
    SectionHeader: Differentiable & Hashable,
    ChildNode: OutlineNodeType & Differentiable & Hashable
>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, RxNSOutlineViewDataSourceType {

    typealias Element = [ArraySection<SectionHeader, ChildNode>]

    typealias SectionHeaderViewProvider = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ header: SectionHeader) -> NSView?
    typealias NodeCellViewProvider = (_ outlineView: NSOutlineView, _ tableColumn: NSTableColumn?, _ node: ChildNode) -> NSView?
    typealias NodeRowViewProvider = (_ outlineView: NSOutlineView, _ node: ChildNode) -> NSTableRowView?

    private let options: RxNSOutlineViewAdapterOptions
    private let sectionHeaderViewProvider: SectionHeaderViewProvider
    private let cellViewProvider: NodeCellViewProvider
    private let rowViewProvider: NodeRowViewProvider?

    private(set) var sections: [ArraySection<SectionHeader, ChildNode>] = []

    /// Reverse lookup from a section header to its child elements. Section headers
    /// are the outline's top-level items, and `NSOutlineView` already requires
    /// top-level items to be unique; that uniqueness lets us resolve a header item
    /// back to its elements in O(1) without scanning `sections`.
    private var elementsByHeader: [SectionHeader: [ChildNode]] = [:]

    init(
        options: RxNSOutlineViewAdapterOptions = [],
        sectionHeaderViewProvider: @escaping SectionHeaderViewProvider,
        cellViewProvider: @escaping NodeCellViewProvider,
        rowViewProvider: NodeRowViewProvider? = nil
    ) {
        self.options = options
        self.sectionHeaderViewProvider = sectionHeaderViewProvider
        self.cellViewProvider = cellViewProvider
        self.rowViewProvider = rowViewProvider
        super.init()
    }

    private func setSections(_ sections: [ArraySection<SectionHeader, ChildNode>]) {
        self.sections = sections
        self.elementsByHeader = Dictionary(
            sections.map { ($0.model, $0.elements) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        switch item {
        case .none:
            return sections.count
        case let header as SectionHeader:
            return elementsByHeader[header]?.count ?? 0
        case let node as ChildNode:
            return node.children.count
        default:
            return 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        switch item {
        case .none:
            return sections[index].model
        case let header as SectionHeader:
            return elementsByHeader[header]?[index] ?? NSNull()
        case let node as ChildNode:
            return node.children[index]
        default:
            return NSNull()
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case let header as SectionHeader:
            return (elementsByHeader[header]?.isEmpty == false)
        case let node as ChildNode:
            return node.isExpandable
        default:
            return false
        }
    }

    // MARK: - NSOutlineViewDelegate

    @objc func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case let header as SectionHeader:
            return sectionHeaderViewProvider(outlineView, tableColumn, header)
        case let node as ChildNode:
            return cellViewProvider(outlineView, tableColumn, node)
        default:
            return nil
        }
    }

    @objc func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let rowViewProvider, let node = item as? ChildNode else { return nil }
        return rowViewProvider(outlineView, node)
    }

    /// `@objc` is mandatory: `isGroupItem` is an optional `NSOutlineViewDelegate`
    /// method, and without it AppKit's `respondsToSelector:` check through the
    /// delegate proxy fails, so group items silently never render.
    @objc func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        item is SectionHeader
    }

    // MARK: - RxNSOutlineViewDataSourceType

    func outlineView(_ outlineView: NSOutlineView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSOutlineViewSectionedAdapter<SectionHeader, ChildNode>, newSections) in
            dataSource.setSections(newSections)
            outlineView.reloadData()
            // Section group items are containers, not content: expand every section
            // after a reload so its objects are visible by default. Child node
            // subtrees keep whatever expansion state the outline resolves for them.
            for section in newSections {
                outlineView.expandItem(section.model)
            }
        }.on(observedEvent)
    }
}
