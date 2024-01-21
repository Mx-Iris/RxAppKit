#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSEvent {
    public enum Scope {
        case local
        case global
    }

    public static func addMonitor(scope: Scope, matching: NSEvent.EventTypeMask) -> ControlEvent<NSEvent> {
        let source = Observable<NSEvent>.create { observer in
            let monitor: Any?
            switch scope {
            case .local:
                monitor = NSEvent.addLocalMonitorForEvents(matching: matching) { event in
                    observer.onNext(event)
                    return event
                }
            case .global:
                monitor = NSEvent.addGlobalMonitorForEvents(matching: matching) { event in
                    observer.onNext(event)
                }
            }
            return Disposables.create {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
        }
        return ControlEvent(events: source)
    }
}

#endif
