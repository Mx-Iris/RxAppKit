//
//  NSWindowController+Rx.swift
//
//
//  Created by JH on 2023/5/24.
//

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSWindowController {
    public var windowWillLoad: ControlEvent<Void> {
        controlEventForSelector(#selector(Base.windowWillLoad))
    }

    public var windowDidLoad: ControlEvent<Void> {
        controlEventForSelector(#selector(Base.windowDidLoad))
    }
}
