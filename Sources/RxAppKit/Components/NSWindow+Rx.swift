import AppKit
import RxSwift

public extension Reactive where Base: NSWindow {
    var didBecomeKey: ControlEvent<Void> {
        controlEventForNotification(Base.didBecomeKeyNotification, object: base)
    }

    var didBecomeMain: ControlEvent<Void> {
        controlEventForNotification(Base.didBecomeMainNotification, object: base)
    }

    var didChangeScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeScreenNotification, object: base)
    }

    var didDeminiaturize: ControlEvent<Void> {
        controlEventForNotification(Base.didDeminiaturizeNotification, object: base)
    }

    var didExpose: ControlEvent<NSRect> {
        controlEventForNotification(Base.didExposeNotification, object: base) {
            ($0.userInfo?["NSExposedRect"] as? NSRect) ?? .zero
        }
    }

    var didMiniaturize: ControlEvent<Void> {
        controlEventForNotification(Base.didMiniaturizeNotification, object: base)
    }

    var didMove: ControlEvent<Void> {
        controlEventForNotification(Base.didMoveNotification, object: base)
    }

    var didResignKey: ControlEvent<Void> {
        controlEventForNotification(Base.didResignKeyNotification, object: base)
    }

    var didResignMain: ControlEvent<Void> {
        controlEventForNotification(Base.didResignMainNotification, object: base)
    }

    var didResize: ControlEvent<Void> {
        controlEventForNotification(Base.didResizeNotification, object: base)
    }

    var didUpdate: ControlEvent<Void> {
        controlEventForNotification(Base.didUpdateNotification, object: base)
    }

    var willClose: ControlEvent<Void> {
        controlEventForNotification(Base.willCloseNotification, object: base)
    }

    var willMiniaturize: ControlEvent<Void> {
        controlEventForNotification(Base.willMiniaturizeNotification, object: base)
    }

    var willMove: ControlEvent<Void> {
        controlEventForNotification(Base.willMoveNotification, object: base)
    }

    var willBeginSheet: ControlEvent<Void> {
        controlEventForNotification(Base.willBeginSheetNotification, object: base)
    }

    var didEndSheet: ControlEvent<Void> {
        controlEventForNotification(Base.didEndSheetNotification, object: base)
    }

    var didChangeBackingProperties: ControlEvent<(oldScaleFacto: NSNumber, oldColorSpace: NSColorSpace)> {
        controlEventForNotification(Base.didChangeBackingPropertiesNotification, object: base) {
            try (castOrThrow(NSNumber.self, $0.userInfo?[Base.oldScaleFactorUserInfoKey]), castOrThrow(NSColorSpace.self, $0.userInfo?[Base.oldColorSpaceUserInfoKey]))
        }
    }

    var didChangeScreenProfile: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeScreenProfileNotification, object: base)
    }

    var willStartLiveResize: ControlEvent<Void> {
        controlEventForNotification(Base.willStartLiveResizeNotification, object: base)
    }

    var didEndLiveResize: ControlEvent<Void> {
        controlEventForNotification(Base.didEndLiveResizeNotification, object: base)
    }

    var willEnterFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.willEnterFullScreenNotification, object: base)
    }

    var didEnterFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didEnterFullScreenNotification, object: base)
    }

    var willExitFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.willExitFullScreenNotification, object: base)
    }

    var didExitFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didExitFullScreenNotification, object: base)
    }

    var willEnterVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.willEnterVersionBrowserNotification, object: base)
    }

    var didEnterVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.didEnterVersionBrowserNotification, object: base)
    }

    var willExitVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.willExitVersionBrowserNotification, object: base)
    }

    var didExitVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.didExitVersionBrowserNotification, object: base)
    }

    var didChangeOcclusionState: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeOcclusionStateNotification, object: base)
    }
}
