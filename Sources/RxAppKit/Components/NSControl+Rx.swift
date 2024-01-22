import AppKit
import RxSwift

extension NSControl: HasTargeAction {}

extension Reactive where Base: NSControl {}
