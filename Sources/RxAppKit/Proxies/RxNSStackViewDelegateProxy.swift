import AppKit
import RxSwift
import RxCocoa

class RxNSStackViewDelegateProxy: DelegateProxy<NSStackView, NSStackViewDelegate>, DelegateProxyType, NSStackViewDelegate {
    public private(set) weak var stackView: NSStackView?
    
    init(stackView: NSStackView) {
        self.stackView = stackView
        super.init(parentObject: stackView, delegateProxy: RxNSStackViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register { RxNSStackViewDelegateProxy(stackView: $0) }
    }
}
