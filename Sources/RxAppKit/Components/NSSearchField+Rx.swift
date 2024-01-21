import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSearchField {
    public var didStartSearching: ControlEvent<Void> {
        let source: Observable<Void> = delegate.methodInvoked(#selector(NSSearchFieldDelegate.searchFieldDidStartSearching(_:))).map { _ in () }
        return ControlEvent(events: source)
    }

    public var didEndSearching: ControlEvent<Void> {
        let source: Observable<Void> = delegate.methodInvoked(#selector(NSSearchFieldDelegate.searchFieldDidEndSearching(_:))).map { _ in () }
        return ControlEvent(events: source)
    }
}
