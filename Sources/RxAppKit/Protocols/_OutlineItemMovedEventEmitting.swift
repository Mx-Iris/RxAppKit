import Foundation
import RxSwift

/// Internal protocol for outline adapters that emit detailed item-moved events during drag-and-drop.
protocol _OutlineItemMovedEventEmitting: AnyObject {
    var _outlineItemMoved: PublishSubject<OutlineMove> { get }
}
