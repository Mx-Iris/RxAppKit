import Foundation
import DifferenceKit

public struct AnyDifferentiable<Element: Hashable>: Hashable, Differentiable {
    let base: Element
    
    init(_ base: Element) {
        self.base = base
    }
}
