import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSSearchField {

    var didStartSearching: ControlEvent<Void> {
        let source: Observable<Void> = delegate.methodInvoked(#selector(NSSearchFieldDelegate.searchFieldDidStartSearching(_:))).map { _ in () }
        return ControlEvent(events: source)
    }

    var didEndSearching: ControlEvent<Void> {
        let source: Observable<Void> = delegate.methodInvoked(#selector(NSSearchFieldDelegate.searchFieldDidEndSearching(_:))).map { _ in () }
        return ControlEvent(events: source)
    }
}
