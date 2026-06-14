import Foundation

/// Controls how an accepted drag-and-drop reorder is committed to the view.
///
/// The reorderable adapters compute the post-drop ordering the same way
/// regardless of strategy; the strategy only decides *when* and *how* the
/// view is refreshed.
public enum ReorderCommitStrategy {
    /// Commit the new ordering to the adapter's backing store and refresh the
    /// view right away (`reloadData()`), inside `acceptDrop`.
    ///
    /// This path is fully self-contained: it does not require the caller to feed
    /// `modelMoved` back into the bound Observable. It is the default and the
    /// behavior used by the non-diffable (reload) adapters, as well as by the
    /// base reorderable adapters when used directly (without Rx).
    case immediate

    /// Stage the new ordering (without mutating the committed backing store) and
    /// wait for the bound Observable to emit the updated data, then apply it
    /// through the diffing / `moveItem` pipeline.
    ///
    /// Used by the diffable adapters so the reorder animates through the same
    /// binding pipeline as every other update. Requires the caller to route
    /// `modelMoved` back into the source sequence.
    case deferredToBinding
}
