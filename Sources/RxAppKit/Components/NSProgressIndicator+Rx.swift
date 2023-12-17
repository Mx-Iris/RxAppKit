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
            target.isIndeterminate = true
            if active {
                target.startAnimation(nil)
            } else {
                target.stopAnimation(nil)
            }
        }
    }
    public func progressValue<Value: BinaryFloatingPoint>() -> Binder<Value> {
        .init(base) { target, progressValue in
            target.isIndeterminate = false
            target.doubleValue = Double(progressValue)
        }
    }
}
