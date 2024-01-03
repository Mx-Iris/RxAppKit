#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension NSMenuItem: HasTargeAction {}

extension Reactive where Base: NSMenuItem {}
#endif
