import AppKit
import RxSwift
import RxCocoa

extension NSSavePanel: @retroactive HasDelegate {
    public typealias Delegate = NSOpenSavePanelDelegate
}

class RxNSOpenSavePanelDelegateProxy: DelegateProxy<NSSavePanel, NSOpenSavePanelDelegate>, DelegateProxyType, NSOpenSavePanelDelegate {
    public private(set) weak var savePanel: NSSavePanel?

    init(savePanel: NSSavePanel) {
        self.savePanel = savePanel
        super.init(parentObject: savePanel, delegateProxy: RxNSOpenSavePanelDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSOpenSavePanelDelegateProxy(savePanel: $0) }
    }
}
