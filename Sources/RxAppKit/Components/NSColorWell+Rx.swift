import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSColorWell {
    public var color: ControlProperty<NSColor> {
        _controlProperty(forKeyPath: \.color)
    }
}
