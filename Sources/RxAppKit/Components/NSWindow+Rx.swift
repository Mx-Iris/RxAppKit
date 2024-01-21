import AppKit
import RxSwift

extension Reactive where Base: NSWindow {
    public var didBecomeKey: ControlEvent<Void> {
        controlEventForNotification(Base.didBecomeKeyNotification, object: base)
    }

    public var didBecomeMain: ControlEvent<Void> {
        controlEventForNotification(Base.didBecomeMainNotification, object: base)
    }

    public var didChangeScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeScreenNotification, object: base)
    }

    public var didDeminiaturize: ControlEvent<Void> {
        controlEventForNotification(Base.didDeminiaturizeNotification, object: base)
    }

    public var didExpose: ControlEvent<NSRect> {
        controlEventForNotification(Base.didExposeNotification, object: base) {
            ($0.userInfo?["NSExposedRect"] as? NSRect) ?? .zero
        }
    }

    public var didMiniaturize: ControlEvent<Void> {
        controlEventForNotification(Base.didMiniaturizeNotification, object: base)
    }

    public var didMove: ControlEvent<Void> {
        controlEventForNotification(Base.didMoveNotification, object: base)
    }

    public var didResignKey: ControlEvent<Void> {
        controlEventForNotification(Base.didResignKeyNotification, object: base)
    }

    public var didResignMain: ControlEvent<Void> {
        controlEventForNotification(Base.didResignMainNotification, object: base)
    }

    public var didResize: ControlEvent<Void> {
        controlEventForNotification(Base.didResizeNotification, object: base)
    }

    public var didUpdate: ControlEvent<Void> {
        controlEventForNotification(Base.didUpdateNotification, object: base)
    }

    public var willClose: ControlEvent<Void> {
        controlEventForNotification(Base.willCloseNotification, object: base)
    }

    public var willMiniaturize: ControlEvent<Void> {
        controlEventForNotification(Base.willMiniaturizeNotification, object: base)
    }

    public var willMove: ControlEvent<Void> {
        controlEventForNotification(Base.willMoveNotification, object: base)
    }

    public var willBeginSheet: ControlEvent<Void> {
        controlEventForNotification(Base.willBeginSheetNotification, object: base)
    }

    public var didEndSheet: ControlEvent<Void> {
        controlEventForNotification(Base.didEndSheetNotification, object: base)
    }

    public var didChangeBackingProperties: ControlEvent<(oldScaleFacto: NSNumber, oldColorSpace: NSColorSpace)> {
        controlEventForNotification(Base.didChangeBackingPropertiesNotification, object: base) {
            try (castOrThrow(NSNumber.self, $0.userInfo?[Base.oldScaleFactorUserInfoKey]), castOrThrow(NSColorSpace.self, $0.userInfo?[Base.oldColorSpaceUserInfoKey]))
        }
    }

    public var didChangeScreenProfile: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeScreenProfileNotification, object: base)
    }

    public var willStartLiveResize: ControlEvent<Void> {
        controlEventForNotification(Base.willStartLiveResizeNotification, object: base)
    }

    public var didEndLiveResize: ControlEvent<Void> {
        controlEventForNotification(Base.didEndLiveResizeNotification, object: base)
    }

    public var willEnterFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.willEnterFullScreenNotification, object: base)
    }

    public var didEnterFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didEnterFullScreenNotification, object: base)
    }

    public var willExitFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.willExitFullScreenNotification, object: base)
    }

    public var didExitFullScreen: ControlEvent<Void> {
        controlEventForNotification(Base.didExitFullScreenNotification, object: base)
    }

    public var willEnterVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.willEnterVersionBrowserNotification, object: base)
    }

    public var didEnterVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.didEnterVersionBrowserNotification, object: base)
    }

    public var willExitVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.willExitVersionBrowserNotification, object: base)
    }

    public var didExitVersionBrowser: ControlEvent<Void> {
        controlEventForNotification(Base.didExitVersionBrowserNotification, object: base)
    }

    public var didChangeOcclusionState: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeOcclusionStateNotification, object: base)
    }
}
