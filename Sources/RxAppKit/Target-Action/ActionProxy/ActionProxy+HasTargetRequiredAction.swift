#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift

private let hasSwizzledKey = AssociationKey<Bool>(default: false)

extension Reactive where Base: NSObject, Base: HasTargetRequiredAction {
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

//             let superclass: AnyClass = class_getSuperclass(swizzleClass(base))!
//            // Set the proxy as the new delegate with all dynamic interception bypassed
//            // by directly invoking setters in the original class.
//            typealias TargetSetter = @convention(c) (NSObject, Selector, AnyObject?) -> Void
//            typealias ActionSetter = @convention(c) (NSObject, Selector, Selector?) -> Void
//
//            let setTargetImpl = class_getMethodImplementation(superclass, #selector(setter: base.target))
//            unsafeBitCast(setTargetImpl, to: TargetSetter.self)(base, #selector(setter: base.target), proxy)
//
//            let setActionImpl = class_getMethodImplementation(superclass, #selector(setter: base.action))
//            unsafeBitCast(setActionImpl, to: ActionSetter.self)(base, #selector(setter: base.action), #selector(proxy.action(_:)))
//
            base.associations.setValue(proxy, forKey: key)
//
//            let newTargetSetterImpl: @convention(block) (NSObject, AnyObject?) -> Void = { object, target in
//                if let proxy = object.associations.value(forKey: key) {
//                    proxy.currentTargetPair.target = target
//                } else {
//                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.target))
//                    unsafeBitCast(impl, to: TargetSetter.self)(object, #selector(setter: self.base.target), target)
//                }
//            }
//
//            let newActionSetterImpl: @convention(block) (NSObject, Selector?) -> Void = { object, action in
//                if let proxy = object.associations.value(forKey: key) {
//                    proxy.currentTargetPair.action = action
//                } else {
//                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.action))
//                    unsafeBitCast(impl, to: ActionSetter.self)(object, #selector(setter: self.base.action), action)
//                }
//            }
//
//            // Swizzle the instance only after setting up the proxy.
//            base.swizzle(
//                (#selector(setter: base.target), newTargetSetterImpl),
//                (#selector(setter: base.action), newActionSetterImpl),
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
