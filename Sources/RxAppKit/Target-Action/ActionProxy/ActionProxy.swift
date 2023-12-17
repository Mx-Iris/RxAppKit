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
