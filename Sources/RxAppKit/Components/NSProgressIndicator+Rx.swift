//
//  NSActivityIndicatorView+Rx.swift
//  
//
//  Created by JH on 2023/6/6.
//

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSProgressIndicator {
    public var isAnimating: Binder<Bool> {
        .init(base) { target, active in
            if active {
                target.startAnimation(nil)
            } else {
                target.stopAnimation(nil)
            }
        }
    }
}
