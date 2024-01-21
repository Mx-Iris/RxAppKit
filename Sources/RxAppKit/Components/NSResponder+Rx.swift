import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSResponder {
    public var mouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseDown(with:)))
    }

    public var rightMouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseDown(with:)))
    }

    public var otherMouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseDown(with:)))
    }

    public var mouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseUp(with:)))
    }

    public var rightMouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseUp(with:)))
    }

    public var otherMouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseUp(with:)))
    }

    public var mouseMoved: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseMoved(with:)))
    }

    public var mouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseDragged(with:)))
    }

    public var scrollWheel: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.scrollWheel(with:)))
    }

    public var rightMouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseDragged(with:)))
    }

    public var otherMouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseDragged(with:)))
    }

    public var mouseEntered: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseEntered(with:)))
    }

    public var mouseExited: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseExited(with:)))
    }

    public var keyDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.keyDown(with:)))
    }

    public var keyUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.keyUp(with:)))
    }

    public var flagsChanged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.flagsChanged(with:)))
    }

    public var tabletPoint: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.tabletPoint(with:)))
    }

    public var tabletProximity: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.tabletProximity(with:)))
    }

    public var cursorUpdate: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.cursorUpdate(with:)))
    }

    public var magnify: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.magnify(with:)))
    }

    public var rotate: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rotate(with:)))
    }

    public var swipe: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.swipe(with:)))
    }

    public var beginGesture: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.beginGesture(with:)))
    }

    public var endGesture: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.endGesture(with:)))
    }

    public var smartMagnify: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.smartMagnify(with:)))
    }

    @available(macOS 10.15, *)
    public var changeMode: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.changeMode(with:)))
    }

    public var touchesBegan: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesBegan(with:)))
    }

    public var touchesMoved: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesMoved(with:)))
    }

    public var touchesEnded: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesEnded(with:)))
    }

    public var touchesCancelled: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesCancelled(with:)))
    }

    public var quickLook: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.quickLook(with:)))
    }

    public var pressureChange: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.pressureChange(with:)))
    }

    public var becomeFirstResponder: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.becomeFirstResponder)).map { _ in }
        return ControlEvent(events: source)
    }

    public var resignFirstResponder: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.resignFirstResponder)).map { _ in }
        return ControlEvent(events: source)
    }

    private func responderEvent(_ selector: Selector) -> ControlEvent<NSEvent> {
        let source = methodInvoked(selector).map {
            try castOrThrow(NSEvent.self, $0[0])
        }
        return ControlEvent(events: source)
    }
}
