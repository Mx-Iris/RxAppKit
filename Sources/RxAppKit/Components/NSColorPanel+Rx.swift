import AppKit
import RxSwift
import RxCocoa

extension NSColorPanel: HasTargeAction {
    public var target: AnyObject? {
        set { setTarget(newValue) }
        get { nil }
    }
    
    public var action: Selector? {
        set { setAction(newValue) }
        get { nil }
    }
    
    var targetSetterSelector: Selector { #selector(setTarget(_:)) }
    var actionSetterSelector: Selector { #selector(setAction(_:)) }
    
}

extension Reactive where Base: NSColorPanel {
    var color: ControlProperty<NSColor> {
        _controlProperty(forKeyPath: \.color)
    }
}
