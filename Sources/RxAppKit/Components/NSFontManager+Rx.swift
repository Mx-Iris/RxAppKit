//
//  NSFontManager+Rx.swift
//  
//
//  Created by JH on 2023/5/3.
//

import Foundation
import AppKit
import RxSwift
import RxCocoa

extension NSFontManager: HasTargetRequiredAction {}

extension Reactive where Base: NSFontManager {
    public var didChangeFont: ControlEvent<NSFont> {
        controlEventForBaseAction { $0.convert(.systemFont(ofSize: NSFont.systemFontSize)) }
    }
}
