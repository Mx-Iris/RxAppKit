import AppKit
import RxSwift
import RxCocoa

extension NSBrowser: HasDelegate {
    public typealias Delegate = NSBrowserDelegate
}

private class BroswerDelegateNotSet: NSObject, NSBrowserDelegate {
    func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
        return 0
    }
    
    func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
        return ""
    }
    
    func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
        true
    }
    
    func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {
        item
    }
}

private let broswerDelegateNotSet = BroswerDelegateNotSet()

open class RxBrowserDelegateProxy: DelegateProxy<NSBrowser, NSBrowserDelegate>, DelegateProxyType, NSBrowserDelegate {
    public private(set) weak var browser: NSBrowser?

    init(browser: NSBrowser) {
        self.browser = browser
        super.init(parentObject: browser, delegateProxy: RxBrowserDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxBrowserDelegateProxy(browser: $0) }
    }
    
    private weak var _requiredMethodsDelegate: NSBrowserDelegate? = broswerDelegateNotSet
    
    public func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
        return _requiredMethodsDelegate?.browser?(browser, numberOfChildrenOfItem: item) ?? broswerDelegateNotSet.browser(browser, numberOfChildrenOfItem: item)
    }
    
    public func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
        _requiredMethodsDelegate?.browser?(browser, child: index, ofItem: item) ?? broswerDelegateNotSet.browser(browser, child: index, ofItem: item)
    }
    
    public func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
        _requiredMethodsDelegate?.browser?(browser, isLeafItem: item) ?? broswerDelegateNotSet.browser(browser, isLeafItem: item)
    }
    
    public func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {
        _requiredMethodsDelegate?.browser?(browser, objectValueForItem: item) ?? broswerDelegateNotSet.browser(browser, objectValueForItem: item)
    }
    
    open override func setForwardToDelegate(_ delegate: DelegateProxy<NSBrowser, NSBrowserDelegate>.Delegate?, retainDelegate: Bool) {
        _requiredMethodsDelegate = delegate
        super.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    }
}
