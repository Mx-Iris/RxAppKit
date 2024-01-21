import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSavePanel {
    public var delegate: DelegateProxy<NSSavePanel, NSOpenSavePanelDelegate> {
        RxNSOpenSavePanelDelegateProxy.proxy(for: base)
    }

    public func setDelegate(_ delegate: NSOpenSavePanelDelegate) -> Disposable {
        RxNSOpenSavePanelDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    public var didChangeSelection: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panelSelectionDidChange(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    public var didChangeToDirURL: ControlEvent<URL?> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:didChangeToDirectoryURL:))).map { a in
            try castOrThrow(URL?.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var willExpand: ControlEvent<Bool> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:willExpand:))).map { a in
            try castOrThrow(Bool.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var validate: ControlEvent<URL> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:validate:))).map { a in
            try castOrThrow(URL.self, a[1])
        }
        return ControlEvent(events: source)
    }

    public var ok: ControlEvent<Base> {
        let source = methodInvoked(#selector(Base.ok(_:))).map { _ in base }
        return ControlEvent(events: source)
    }

    public var cancel: ControlEvent<Base> {
        let source = methodInvoked(#selector(Base.cancel(_:))).map { _ in base }
        return ControlEvent(events: source)
    }

    public func begin() -> ControlEvent<(panel: Base, result: NSApplication.ModalResponse)> {
        let source = Observable<(panel: Base, result: NSApplication.ModalResponse)>.create { [weak panel = base] observer in
            guard let panel else {
                observer.on(.completed)
                return Disposables.create {}
            }
            base.begin { result in
                observer.on(.next((panel, result)))
                observer.on(.completed)
            }
            return Disposables.create {}
        }
        .subscribe(on: MainScheduler.instance)
        return ControlEvent(events: source)
    }

    public func beginSheetModal(for window: NSWindow) -> ControlEvent<(panel: Base, result: NSApplication.ModalResponse)> {
        let source = Observable<(panel: Base, result: NSApplication.ModalResponse)>.create { [weak panel = base] observer in
            guard let panel else {
                observer.on(.completed)
                return Disposables.create {}
            }
            base.beginSheetModal(for: window) { result in
                observer.on(.next((panel, result)))
                observer.on(.completed)
            }
            return Disposables.create {}
        }
        .subscribe(on: MainScheduler.instance)
        return ControlEvent(events: source)
    }
}
