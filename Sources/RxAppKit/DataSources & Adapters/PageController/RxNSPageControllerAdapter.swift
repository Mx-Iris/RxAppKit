//
//  RxPageControllerAdapter.swift
//  
//
//  Created by JH on 2023/9/9.
//

import AppKit
import RxSwift
import RxCocoa

open class RxNSPageControllerAdapter<Item: PageControllerItem>: PageControllerAdapter<Item>, RxNSPageControllerDelegateType {
    public typealias Element = [Item]
    
    open func pageController(_ pageController: NSPageController, observedEvent: Event<Element>) {
        Binder(self) { adapter, newItems in
            guard !newItems.isEmpty else { return }
            adapter.items = [:]
            for item in newItems {
                adapter.items[item.identifier] = item
            }
            pageController.arrangedObjects = newItems
        }.on(observedEvent)
    }
}
