import AppKit
import RxSwift
import RxCocoa

extension NSPageController: @retroactive HasDelegate {
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

class RxNSPageControllDelegateProxy: DelegateProxy<NSPageController, NSPageControllerDelegate>, RequiredMethodDelegateProxyType, NSPageControllerDelegate {
    public private(set) weak var pageController: NSPageController?

    init(pageControll: NSPageController) {
        self.pageController = pageControll
        super.init(parentObject: pageControll, delegateProxy: RxNSPageControllDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSPageControllDelegateProxy(pageControll: $0) }
    }
    
    let _requiredMethodsDelegate: ObjectContainer<NSPageControllerDelegate> = .init()
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        _requiredMethodsDelegate.object?.pageController?(pageController, identifierFor: object) ?? pageControllerDelegateNotSet.pageController(pageController, identifierFor: object)
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        _requiredMethodsDelegate.object?.pageController?(pageController, viewControllerForIdentifier: identifier) ?? pageControllerDelegateNotSet.pageController(pageController, viewControllerForIdentifier: identifier)
    }
    
}
