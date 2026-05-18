import Foundation

/// Behavior switches for `RxNSTableViewAdapter`.
///
/// The adapter consults these options at bind time to choose which update
/// path to take:
///
/// - `.diffable` drives incremental updates via DifferenceKit's
///   `StagedChangeset`. Without it the adapter falls back to `reloadData()`
///   on every event, which is the safest baseline.
/// - `.reorderable` registers the table view for drag-and-drop reordering
///   and feeds accepted drops back into the bound model.
///
/// The options are independent and can be combined. The four combinations
/// produce the following behaviors:
///
/// | options                     | non-drag update    | drag update       |
/// | --------------------------- | ------------------ | ----------------- |
/// | `[]`                        | `reloadData()`     | n/a               |
/// | `[.diffable]`               | `StagedChangeset`  | n/a               |
/// | `[.reorderable]`            | `reloadData()`     | model round-trip  |
/// | `[.diffable, .reorderable]` | `StagedChangeset`  | model round-trip  |
public struct RxNSTableViewAdapterOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Use DifferenceKit's `StagedChangeset` to compute and apply incremental
    /// updates. Without it, every observed event triggers `reloadData()`.
    public static let diffable = RxNSTableViewAdapterOptions(rawValue: 1 << 0)

    /// Enable drag-and-drop reordering. Causes the adapter to register the
    /// table view for reorder pasteboard types and to emit `itemMoved` /
    /// `modelMoved` events when a drop is accepted.
    public static let reorderable = RxNSTableViewAdapterOptions(rawValue: 1 << 1)
}
