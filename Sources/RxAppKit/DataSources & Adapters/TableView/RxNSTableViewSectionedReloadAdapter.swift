import AppKit
import RxSwift
import DifferenceKit

/// Rx data source adapter for a *sectioned* `NSTableView`. Reloads the table on
/// every observed event. Bind an `Observable<[ArraySection<SectionHeader, Item>]>`
/// (or the friendlier `[TableViewSection<SectionHeader, Item>]` alias).
///
/// `NSTableView` has no section-level batch-update API, so updates always go
/// through `reloadData()`. Animated and reorderable sectioned variants are
/// deliberately not provided yet.
open class RxNSTableViewSectionedReloadAdapter<SectionHeader: Differentiable, Item: Differentiable>:
    SectionedTableViewAdapter<SectionHeader, Item>,
    RxNSTableViewDataSourceType {
    public typealias Element = [ArraySection<SectionHeader, Item>]

    open func tableView(_ tableView: NSTableView, observedEvent: Event<Element>) {
        Binder<Element>(self) { (dataSource: RxNSTableViewSectionedReloadAdapter<SectionHeader, Item>, newSections) in
            dataSource.setSections(newSections)
            tableView.reloadData()
        }.on(observedEvent)
    }
}
