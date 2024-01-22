import AppKit
import RxSwift
import RxCocoa

extension NSToolbarItem: HasTargeAction {}

extension Reactive where Base: NSToolbarItem {}
