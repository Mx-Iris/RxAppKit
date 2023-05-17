import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSSavePanel {
    var delegate: DelegateProxy<NSSavePanel, NSOpenSavePanelDelegate> {
        RxNSOpenSavePanelDelegateProxy.proxy(for: base)
    }

    func setDelegate(_ delegate: NSOpenSavePanelDelegate) -> Disposable {
        RxNSOpenSavePanelDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: base)
    }

    var didChangeSelection: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panelSelectionDidChange(_:))).map { _ in }
        return ControlEvent(events: source)
    }

    var didChangeToDirURL: ControlEvent<URL?> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:didChangeToDirectoryURL:))).map { a in
            try castOrThrow(URL?.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var willExpand: ControlEvent<Bool> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:willExpand:))).map { a in
            try castOrThrow(Bool.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var validate: ControlEvent<URL> {
        let source = delegate.methodInvoked(#selector(NSOpenSavePanelDelegate.panel(_:validate:))).map { a in
            try castOrThrow(URL.self, a[1])
        }
        return ControlEvent(events: source)
    }

    var ok: ControlEvent<Base> {
        let source = methodInvoked(#selector(Base.ok(_:))).map { _ in base }
        return ControlEvent(events: source)
    }

    var cancel: ControlEvent<Base> {
        let source = methodInvoked(#selector(Base.cancel(_:))).map { _ in base }
        return ControlEvent(events: source)
    }
    
    func begin() -> ControlEvent<(panel: Base, result: NSApplication.ModalResponse)> {
        let source = Observable<(panel: Base, result: NSApplication.ModalResponse)>.create { [weak panel = base] observer in
            guard let panel = panel else {
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
    
    func beginSheetModal(for window: NSWindow) -> ControlEvent<(panel: Base, result: NSApplication.ModalResponse)> {
        let source = Observable<(panel: Base, result: NSApplication.ModalResponse)>.create { [weak panel = base] observer in
            guard let panel = panel else {
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
