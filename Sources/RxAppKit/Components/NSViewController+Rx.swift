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
    public var viewDidLoad: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidLoad))
    }
    
    public var viewWillAppear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillAppear))
    }
    
    public var viewDidAppear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidAppear))
    }
    
    public var viewWillDisappear: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillDisappear))
    }
    
    public var viewWillLayout: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewWillLayout))
    }
    
    public var viewDidLayout: ControlEvent<Void> {
        controlEvent(for: #selector(Base.viewDidLayout))
    }
    
    public var firstLayout: ControlEvent<Void> {
        ControlEvent(events: viewDidLayout.take(1))
    }
    
    private func controlEvent(for selector: Selector) -> ControlEvent<Void> {
        let source = methodInvoked(selector).map { _ in }
        return ControlEvent(events: source)
    }
    
}
