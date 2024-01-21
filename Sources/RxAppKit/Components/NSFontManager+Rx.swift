import AppKit
import RxSwift
import RxCocoa

extension NSFontManager: HasTargetRequiredAction {}

extension Reactive where Base: NSFontManager {
    public var didChangeFont: ControlEvent<NSFont> {
        controlEventForBaseAction { $0.convert(.systemFont(ofSize: NSFont.systemFontSize)) }
    }
}
