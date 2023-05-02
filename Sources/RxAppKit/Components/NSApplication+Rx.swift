import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSApplication {
    var didFinishLaunching: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didFinishLaunchingNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var didBecomeActive: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didBecomeActiveNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var didHide: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didHideNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var didResignActive: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didResignActiveNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var didUnhide: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didUnhideNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var didUpdate: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.didUpdateNotification).map { _ in }
        return ControlEvent(events: source)
    }
   
    var willBecomeActive: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willBecomeActiveNotification).map { _ in }
        return ControlEvent(events: source)
    }
   
    var willHide: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willHideNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var willResignActive: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willResignActiveNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var willUnhide: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willUnhideNotification).map { _ in }
        return ControlEvent(events: source)
    }
   
    var willUpdate: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willUpdateNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
    var willTerminate: ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(NSApplication.willTerminateNotification).map { _ in }
        return ControlEvent(events: source)
    }
    
}
