#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@objc
protocol HasTargetRequiredAction: AnyObject {
    var target: AnyObject? { set get }
    var action: Selector { set get }
}

#endif
