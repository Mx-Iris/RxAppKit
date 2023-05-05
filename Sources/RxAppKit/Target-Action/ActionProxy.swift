import AppKit
import RxSwift

final class ActionProxy<Owner: AnyObject>: NSObject {
    class Pair {
        weak var target: AnyObject?
        var action: Selector?
        var doubleAction: Selector?
        init() {}
        init(target: AnyObject?, action: Selector?, doubleAction: Selector?) {
            self.target = target
            self.action = action
            self.doubleAction = doubleAction
        }

        deinit {
            target = nil
            action = nil
            doubleAction = nil
        }
    }

    unowned let owner: Owner

    init(owner: Owner) {
        self.owner = owner
    }

    var hasTargetSwizzled: Bool = false
    var hasActionSwizzled: Bool = false
    var hasDoubleActionSwizzled: Bool = false

    var currentTargetPair: Pair = .init()
    var forwardTargetPairs: [Pair] = []

    func addForwardTarget(_ target: AnyObject, action: Selector?, doubleAction: Selector?) {
        forwardTargetPairs.append(Pair(target: target, action: action, doubleAction: doubleAction))
    }

    @objc func action(_ sender: Any?) {
        func invoke(_ pair: Pair) {
            guard let action = pair.action else { return }
            if let app = NSApp {
                app.sendAction(action, to: pair.target, from: sender)
            } else {
                _ = pair.target?.perform(action, with: sender)
            }
        }
        invoke(currentTargetPair)
        forwardTargetPairs.forEach(invoke(_:))
    }

    @objc func doubleAction(_ sender: Any?) {
        func invoke(_ pair: Pair) {
            guard let target = pair.target, let doubleAction = pair.doubleAction else { return }
            if let app = NSApp {
                app.sendAction(doubleAction, to: target, from: sender)
            } else {
                _ = target.perform(doubleAction, with: sender)
            }
        }
        invoke(currentTargetPair)
        forwardTargetPairs.forEach(invoke(_:))
    }
}

private let hasSwizzledKey = AssociationKey<Bool>(default: false)

extension Reactive where Base: NSObject, Base: HasTargeAction {
    var proxy: ActionProxy<Base> {
        let key = AssociationKey<ActionProxy<Base>?>(#function as StaticString)
        return synchronized(base) {
            if let proxy = base.associations.value(forKey: key) {
                return proxy
            }

            let superclass: AnyClass = class_getSuperclass(swizzleClass(base))!

            let proxy = ActionProxy<Base>(owner: base)
            proxy.currentTargetPair.target = base.target
            proxy.currentTargetPair.action = base.action
            // Set the proxy as the new delegate with all dynamic interception bypassed
            // by directly invoking setters in the original class.
            typealias TargetSetter = @convention(c) (NSObject, Selector, AnyObject?) -> Void
            typealias ActionSetter = @convention(c) (NSObject, Selector, Selector?) -> Void

            let setTargetImpl = class_getMethodImplementation(superclass, #selector(setter: base.target))
            unsafeBitCast(setTargetImpl, to: TargetSetter.self)(base, #selector(setter: base.target), proxy)

            let setActionImpl = class_getMethodImplementation(superclass, #selector(setter: base.action))
            unsafeBitCast(setActionImpl, to: ActionSetter.self)(base, #selector(setter: base.action), #selector(proxy.action(_:)))

            base.associations.setValue(proxy, forKey: key)

            let newTargetSetterImpl: @convention(block) (NSObject, AnyObject?) -> Void = { object, target in
                if let proxy = object.associations.value(forKey: key) {
                    proxy.currentTargetPair.target = target
                } else {
                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.target))
                    unsafeBitCast(impl, to: TargetSetter.self)(object, #selector(setter: self.base.target), target)
                }
            }

            let newActionSetterImpl: @convention(block) (NSObject, Selector?) -> Void = { object, action in
                if let proxy = object.associations.value(forKey: key) {
                    proxy.currentTargetPair.action = action
                } else {
                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.action))
                    unsafeBitCast(impl, to: ActionSetter.self)(object, #selector(setter: self.base.action), action)
                }
            }

            // Swizzle the instance only after setting up the proxy.
            base.swizzle(
                (#selector(setter: base.target), newTargetSetterImpl),
                (#selector(setter: base.action), newActionSetterImpl),
                key: hasSwizzledKey
            )

            proxy.hasTargetSwizzled = true
            proxy.hasActionSwizzled = true

            return proxy
        }
    }
}

private let hasDoubleActionSwizzledKey = AssociationKey<Bool>(default: false)

extension Reactive where Base: NSObject, Base: HasDoubleAction {
    var doubleActionProxy: ActionProxy<Base> {
        let key = AssociationKey<ActionProxy<Base>?>(#function as StaticString)
        return synchronized(base) {
            let proxy = proxy

            if proxy.hasDoubleActionSwizzled {
                return proxy
            }

            let superclass: AnyClass = class_getSuperclass(swizzleClass(base))!

            proxy.currentTargetPair.doubleAction = base.doubleAction

            // Set the proxy as the new delegate with all dynamic interception bypassed
            // by directly invoking setters in the original class.
            typealias ActionSetter = @convention(c) (NSObject, Selector, Selector?) -> Void

            let setDoubleActionImpl = class_getMethodImplementation(superclass, #selector(setter: base.doubleAction))
            unsafeBitCast(setDoubleActionImpl, to: ActionSetter.self)(base, #selector(setter: base.doubleAction), #selector(proxy.doubleAction(_:)))

            let newDoubleActionSetterImpl: @convention(block) (NSObject, Selector?) -> Void = { object, doubleAction in
                if let proxy = object.associations.value(forKey: key) {
                    proxy.currentTargetPair.doubleAction = doubleAction
                } else {
                    let impl = class_getMethodImplementation(superclass, #selector(setter: self.base.doubleAction))
                    unsafeBitCast(impl, to: ActionSetter.self)(object, #selector(setter: self.base.doubleAction), doubleAction)
                }
            }

            // Swizzle the instance only after setting up the proxy.
            base.swizzle(
                (#selector(setter: base.doubleAction), newDoubleActionSetterImpl),
                key: hasDoubleActionSwizzledKey
            )

            proxy.hasDoubleActionSwizzled = true

            return proxy
        }
    }
}

func synchronized<Result>(_ token: AnyObject, execute: () throws -> Result) rethrows -> Result {
    objc_sync_enter(token)
    defer { objc_sync_exit(token) }
    return try execute()
}
