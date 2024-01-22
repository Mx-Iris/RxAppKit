#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

public protocol RxToolbarItemRepresentable {
    var isDefault: Bool { get }
    var isAllowed: Bool { get }
    var isSelectable: Bool { get }
    var shouldEnable: Bool { get }
    var identifier: NSToolbarItem.Identifier { get }
}

extension RxToolbarItemRepresentable {
    public var shouldEnable: Bool { true }
}

#endif
