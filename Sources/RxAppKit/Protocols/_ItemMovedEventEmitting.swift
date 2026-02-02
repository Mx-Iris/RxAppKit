import Foundation
import RxSwift

/// Internal protocol for adapters that emit item-moved events during drag-and-drop reordering.
protocol _ItemMovedEventEmitting: AnyObject {
    var _itemMoved: PublishSubject<(sourceIndexes: IndexSet, destinationIndex: Int)> { get }
    /// Emits the new complete items array (type-erased) after reordering.
    var _modelMoved: PublishSubject<[Any]> { get }
}
