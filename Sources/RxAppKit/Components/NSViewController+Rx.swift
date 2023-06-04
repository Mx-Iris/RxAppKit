//
//  NSViewController+Rx.swift
//  
//
//  Created by JH on 2023/5/24.
//

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSViewController {
    var viewDidLoad: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidLoad))
    }
    
    var viewWillAppear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillAppear))
    }
    
    var viewDidAppear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidAppear))
    }
    
    var viewWillDisappear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillDisappear))
    }
    
    var viewWillLayout: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillLayout))
    }
    
    var viewDidLayout: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidLayout))
    }
    
    private func controlEvent(for selector: Selector) -> ControlEvent<Void> {
        let source = methodInvoked(selector).map { _ in }
        return ControlEvent(events: source)
    }
    
}
