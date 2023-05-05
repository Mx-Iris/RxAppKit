//
//  NSSplitView+Rx.swift
//  
//
//  Created by JH on 2023/5/3.
//

import Foundation
import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSplitView {
    var willResizeSubviews: ControlEvent<Void> {
        controlEventForNotification(Base.willResizeSubviewsNotification, object: base)
    }
    var didResizeSubviews: ControlEvent<Void> {
        controlEventForNotification(Base.didResizeSubviewsNotification, object: base)
    }
}
