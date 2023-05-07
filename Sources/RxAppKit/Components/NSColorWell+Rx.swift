import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSColorWell {
    var color: ControlProperty<NSColor> {
        controlProperty(forKeyPath: \.color)
    }
}
