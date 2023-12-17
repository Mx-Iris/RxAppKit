#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

private let hasSwizzledKey = AssociationKey<Bool>(default: false)

extension Reactive where Base: NSObject, Base: HasTargeAction {
    var proxy: ActionProxy<Base> {
        let key = AssociationKey<ActionProxy<Base>?>(#function as StaticString)
        return synchronized(base) {
            if let proxy = base.associations.value(forKey: key) {
                return proxy
            }

            let proxy = ActionProxy<Base>(owner: base)
            proxy.currentTargetPair.target = base.target
            proxy.currentTargetPair.action = base.action
            base.target = proxy
            base.action = #selector(proxy.action(_:))

//            let superclass: AnyClass = class_getSuperclass(swizzleClass(base))!
//            // Set the proxy as the new delegate with all dynamic interception bypassed
//            // by directly invoking setters in the original class.
//            typealias TargetSetter = @convention(c) (NSObject, Selector, AnyObject?) -> Void
//            typealias ActionSetter = @convention(c) (NSObject, Selector, Selector?) -> Void
//
//            let setTargetImpl = class_getMethodImplementation(superclass, base.targetSetterSelector)
//            unsafeBitCast(setTargetImpl, to: TargetSetter.self)(base, base.targetSetterSelector, proxy)
//
//            let setActionImpl = class_getMethodImplementation(superclass, base.actionSetterSelector)
//            unsafeBitCast(setActionImpl, to: ActionSetter.self)(base, base.actionSetterSelector, #selector(proxy.action(_:)))

            base.associations.setValue(proxy, forKey: key)

//            let newTargetSetterImpl: @convention(block) (NSObject, AnyObject?) -> Void = { object, target in
//                if let proxy = object.associations.value(forKey: key) {
//                    proxy.currentTargetPair.target = target
//                } else {
//                    let impl = class_getMethodImplementation(superclass, base.targetSetterSelector)
//                    unsafeBitCast(impl, to: TargetSetter.self)(object, base.targetSetterSelector, target)
//                }
//            }
//
//            let newActionSetterImpl: @convention(block) (NSObject, Selector?) -> Void = { object, action in
//                if let proxy = object.associations.value(forKey: key) {
//                    proxy.currentTargetPair.action = action
//                } else {
//                    let impl = class_getMethodImplementation(superclass, base.actionSetterSelector)
//                    unsafeBitCast(impl, to: ActionSetter.self)(object, base.actionSetterSelector, action)
//                }
//            }
//
//            // Swizzle the instance only after setting up the proxy.
//            base.swizzle(
//                (base.targetSetterSelector, newTargetSetterImpl),
//                (base.actionSetterSelector, newActionSetterImpl),
//                key: hasSwizzledKey
//            )
//
//            proxy.hasTargetSwizzled = true
//            proxy.hasActionSwizzled = true

            return proxy
        }
    }
}
#endif
