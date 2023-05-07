import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSAlert {
    func beginSheetModal(for window: NSWindow) -> ControlEvent<NSApplication.ModalResponse> {
        let source = Observable.create { observer in
            base.beginSheetModal(for: window) { response in
                observer.on(.next(response))
                observer.on(.completed)
            }
            return Disposables.create {}
        }
        .subscribe(on: MainScheduler.instance)
        return ControlEvent(events: source)
    }
}
