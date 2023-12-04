//
//  PageControllerAdapter.swift
//  
//
//  Created by JH on 2023/9/9.
//

import AppKit

public protocol PageControllerItem {
    var identifier: String { get }
}

open class PageControllerAdapter<Item: PageControllerItem>: NSObject, NSPageControllerDelegate {
    public typealias ItemProvider<ItemType: PageControllerItem> = (NSPageController, String, ItemType) -> NSViewController
    
    public var itemProvider: ItemProvider<Item>
    
    internal var items: [String: Item] = [:]
    
    public init(itemProvider: @escaping ItemProvider<Item>) {
        self.itemProvider = itemProvider
    }
    
    open func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        guard let item = object as? PageControllerItem else {
            rxFatalError("Internal Error")
        }
        return item.identifier
    }
    
    open func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        guard let item = items[identifier] else {
            rxFatalError("Internal Error")
        }
        return itemProvider(pageController, identifier, item)
    }
    
    public func pageController(_ pageController: NSPageController, frameFor object: Any?) -> NSRect {
        pageController.view.bounds
    }
}
