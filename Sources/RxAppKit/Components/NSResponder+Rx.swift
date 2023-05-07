import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSResponder {
    var mouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseDown(with:)))
    }

    var rightMouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseDown(with:)))
    }

    var otherMouseDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseDown(with:)))
    }

    var mouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseUp(with:)))
    }

    var rightMouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseUp(with:)))
    }

    var otherMouseUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseUp(with:)))
    }

    var mouseMoved: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseMoved(with:)))
    }

    var mouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseDragged(with:)))
    }

    var scrollWheel: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.scrollWheel(with:)))
    }

    var rightMouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rightMouseDragged(with:)))
    }

    var otherMouseDragged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.otherMouseDragged(with:)))
    }

    var mouseEntered: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseEntered(with:)))
    }

    var mouseExited: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.mouseExited(with:)))
    }

    var keyDown: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.keyDown(with:)))
    }

    var keyUp: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.keyUp(with:)))
    }

    var flagsChanged: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.flagsChanged(with:)))
    }

    var tabletPoint: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.tabletPoint(with:)))
    }

    var tabletProximity: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.tabletProximity(with:)))
    }

    var cursorUpdate: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.cursorUpdate(with:)))
    }

    var magnify: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.magnify(with:)))
    }

    var rotate: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.rotate(with:)))
    }

    var swipe: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.swipe(with:)))
    }

    var beginGesture: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.beginGesture(with:)))
    }

    var endGesture: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.endGesture(with:)))
    }

    var smartMagnify: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.smartMagnify(with:)))
    }

    @available(macOS 10.15, *)
    var changeMode: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.changeMode(with:)))
    }

    var touchesBegan: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesBegan(with:)))
    }

    var touchesMoved: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesMoved(with:)))
    }

    var touchesEnded: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesEnded(with:)))
    }

    var touchesCancelled: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.touchesCancelled(with:)))
    }

    var quickLook: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.quickLook(with:)))
    }

    var pressureChange: ControlEvent<NSEvent> {
        responderEvent(#selector(Base.pressureChange(with:)))
    }

    var becomeFirstResponder: ControlEvent<Void> {
        let source = methodInvoked(#selector(Base.becomeFirstResponder)).map { _ in }
        return ControlEvent(events: source)
    }
    
    var resignFirstResponder: ControlEvent<Void> {
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
