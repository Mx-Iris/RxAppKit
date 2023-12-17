#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

private let hasDoubleActionSwizzledKey = AssociationKey<Bool>(default: false)

extension Reactive where Base: NSObject, Base: HasDoubleAction {
    var doubleActionProxy: ActionProxy<Base> {
//        let key = AssociationKey<ActionProxy<Base>?>(#function as StaticString)
        return synchronized(base) {
            let proxy = proxy

            if proxy.hasDoubleActionSwizzled {
                return proxy
            }

            proxy.currentTargetPair.doubleAction = base.doubleAction
            base.doubleAction = #selector(proxy.doubleAction(_:))

//            let superclass: AnyClass = class_getSuperclass(swizzleClass(base))!
//
//            // Set the proxy as the new delegate with all dynamic interception bypassed
//            // by directly invoking setters in the original class.
//            typealias ActionSetter = @convention(c) (NSObject, Selector, Selector?) -> Void
//
//            let setDoubleActionImpl = class_getMethodImplementation(superclass, #selector(setter: base.doubleAction))
//            unsafeBitCast(setDoubleActionImpl, to: ActionSetter.self)(base, #selector(setter: base.doubleAction), #selector(proxy.doubleAction(_:)))
//
//            let newDoubleActionSetterImpl: @convention(block) (NSObject, Selector?) -> Void = { object, doubleAction in
//                if let proxy = object.associations.value(forKey: key) {
//                    proxy.currentTargetPair.doubleAction = doubleAction
//                } else {
//                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.doubleAction))
//                    unsafeBitCast(impl, to: ActionSetter.self)(object, #selector(setter: self.base.doubleAction), doubleAction)
//                }
//            }
//
//            // Swizzle the instance only after setting up the proxy.
//            base.swizzle(
//                (#selector(setter: base.doubleAction), newDoubleActionSetterImpl),
//                key: hasDoubleActionSwizzledKey
//            )
//
            proxy.hasDoubleActionSwizzled = true

            return proxy
        }
    }
}
#endif
