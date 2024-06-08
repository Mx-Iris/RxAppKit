#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@objc
public protocol HasDoubleAction: HasTargeAction {
    var doubleAction: Selector? { set get }
}



#endif
