import Foundation

/// Behavior switches for the Rx outline-view adapters.
///
/// `RxNSOutlineViewAdapter` and `RxNSOutlineViewRootNodeAdapter` consult these
/// options at bind time to choose which update path to take:
///
/// - `.diffable` drives incremental, animated updates via DifferenceKit's
///   `StagedChangeset`. Without it the adapter falls back to `reloadData()`
///   on every event, which is the safest baseline.
/// - `.reorderable` registers the outline view for drag-and-drop reordering
///   and drives accepted drops through
///   `NSOutlineView.moveItem(at:inParent:to:inParent:)` so the view's row
///   mapping stays in sync.
///
/// The options are independent and can be combined. The four combinations
/// produce the following behaviors:
///
/// | options                     | non-drag update    | drag update     |
/// | --------------------------- | ------------------ | --------------- |
/// | `[]`                        | `reloadData()`     | n/a             |
/// | `[.diffable]`               | `StagedChangeset`  | n/a             |
/// | `[.reorderable]`            | `reloadData()`     | `applyDragMove` |
/// | `[.diffable, .reorderable]` | `StagedChangeset`  | `applyDragMove` |
public struct RxNSOutlineViewAdapterOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Use DifferenceKit's `StagedChangeset` to compute and animate
    /// incremental updates. Without it, every observed event triggers
    /// `reloadData()`.
    public static let diffable = RxNSOutlineViewAdapterOptions(rawValue: 1 << 0)

    /// Enable drag-and-drop reordering. Causes the adapter to register the
    /// outline view for reorder pasteboard types and to drive accepted drops
    /// through `NSOutlineView.moveItem(at:inParent:to:inParent:)`.
    public static let reorderable = RxNSOutlineViewAdapterOptions(rawValue: 1 << 1)
}
