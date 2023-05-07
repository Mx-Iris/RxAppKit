import AppKit
import RxSwift
import RxCocoa

extension NSFontManager: HasTargetRequiredAction {}

public extension Reactive where Base: NSFontManager {
    var didChangeFont: ControlEvent<NSFont> {
        controlEventForBaseAction { $0.convert(.systemFont(ofSize: NSFont.systemFontSize)) }
    }
}
