import AppKit
import RxSwift
import RxCocoa

extension NSBrowser: @retroactive HasDelegate {
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

class RxNSBrowserDelegateProxy: DelegateProxy<NSBrowser, NSBrowserDelegate>, RequiredMethodsDelegateProxyType, NSBrowserDelegate {
    
    public private(set) weak var browser: NSBrowser?

    public init(browser: NSBrowser) {
        self.browser = browser
        super.init(parentObject: browser, delegateProxy: RxNSBrowserDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        register { RxNSBrowserDelegateProxy(browser: $0) }
    }

    let _requiredMethodsDelegate = ObjectContainer<NSBrowserDelegate>()

    public func rootItem(for browser: NSBrowser) -> Any? {
        _requiredMethodsDelegate.object?.rootItem?(for: browser)
    }

    public func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
        _requiredMethodsDelegate.object?.browser?(browser, numberOfChildrenOfItem: item) ?? broswerDelegateNotSet.browser(browser, numberOfChildrenOfItem: item)
    }

    public func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
        _requiredMethodsDelegate.object?.browser?(browser, child: index, ofItem: item) ?? broswerDelegateNotSet.browser(browser, child: index, ofItem: item)
    }

    public func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
        _requiredMethodsDelegate.object?.browser?(browser, isLeafItem: item) ?? broswerDelegateNotSet.browser(browser, isLeafItem: item)
    }

    public func browser(_ browser: NSBrowser, objectValueForItem item: Any?) -> Any? {
        _requiredMethodsDelegate.object?.browser?(browser, objectValueForItem: item) ?? broswerDelegateNotSet.browser(browser, objectValueForItem: item)
    }

    public func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
        _requiredMethodsDelegate.object?.browser?(sender, willDisplayCell: cell, atRow: row, column: column)
    }
}
