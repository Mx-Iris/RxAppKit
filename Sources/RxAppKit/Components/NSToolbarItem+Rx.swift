//
//  NSToolbarItem+Rx.swift
//
//
//  Created by JH on 2023/6/4.
//

import AppKit
import RxSwift
import RxCocoa

extension NSToolbarItem: HasTargeAction {}

extension Reactive where Base: NSToolbarItem {
    public var click: ControlEvent<Void> {
        _controlEventForBaseAction { _ in }
    }
}
