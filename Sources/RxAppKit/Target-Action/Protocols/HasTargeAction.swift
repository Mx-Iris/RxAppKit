#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@objc
public protocol HasTargeAction: AnyObject where Self: NSObject {
    var target: AnyObject? { set get }
    var action: Selector? { set get }
}

extension HasTargeAction where Self: AnyObject {
    var targetSetterSelector: Selector { #selector(setter: target) }
    var actionSetterSelector: Selector { #selector(setter: action) }
}


#endif
