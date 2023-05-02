import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: AnyObject {
    /**
     Helper to make sure that `Observable` returned from `createCachedObservable` is only created once.
     This is important because there is only one `target` and `action` properties on `NSControl` or `UIBarButtonItem`.
     */
    func lazyInstanceObservable<T: AnyObject>(_ key: UnsafeRawPointer, createCachedObservable: () -> T) -> T {
        if let value = objc_getAssociatedObject(self.base, key) {
            return value as! T
        }
        
        let observable = createCachedObservable()
        
        objc_setAssociatedObject(self.base, key, observable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return observable
    }
    
    func controlEventForNotification(_ notificationName: Notification.Name, object: AnyObject?) -> ControlEvent<Void> {
        let source = NotificationCenter.default.rx.notification(notificationName, object: object).map { _ in }
        return ControlEvent(events: source)
    }
}
