import AppKit
import RxSwift
import RxCocoa

extension NSPageController: HasDelegate {
    public typealias Delegate = NSPageControllerDelegate
}

private class PageControllDelegateNotSet: NSObject, NSPageControllerDelegate {
    private class ViewController: NSViewController {
        override func loadView() {
            view = NSView()
        }
    }
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return ""
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        return ViewController()
    }
}

private let pageControllerDelegateNotSet = PageControllDelegateNotSet()

class RxNSPageControllDelegateProxy: DelegateProxy<NSPageController, NSPageControllerDelegate>, DelegateProxyType, NSPageControllerDelegate {
    public private(set) weak var pageController: NSPageController?

    init(pageControll: NSPageController) {
        self.pageController = pageControll
        super.init(parentObject: pageControll, delegateProxy: RxNSPageControllDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSPageControllDelegateProxy(pageControll: $0) }
    }
    
    private var _requiredMethodsDelegate: NSPageControllerDelegate?
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        _requiredMethodsDelegate?.pageController?(pageController, identifierFor: object) ?? pageControllerDelegateNotSet.pageController(pageController, identifierFor: object)
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        _requiredMethodsDelegate?.pageController?(pageController, viewControllerForIdentifier: identifier) ?? pageControllerDelegateNotSet.pageController(pageController, viewControllerForIdentifier: identifier)
    }
    
    func setRequiredMethodsDelegate(_ requiredMethodsDelegate: NSPageControllerDelegate) -> Disposable {
        _requiredMethodsDelegate = requiredMethodsDelegate
        return Disposables.create { [weak self] in
            guard let self = self else { return }
            _requiredMethodsDelegate = nil
        }
    }
}
