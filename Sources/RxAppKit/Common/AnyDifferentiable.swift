//
//  AnyDifferentiable.swift
//  
//
//  Created by JH on 2023/8/13.
//

import Foundation
import DifferenceKit

struct AnyDifferentiable<Element: Hashable>: Hashable, Differentiable {
    let base: Element
    
    init(_ base: Element) {
        self.base = base
    }
}
