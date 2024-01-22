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

enum SystemToolbarItemIdentifier {
    static let identifiers: Set<NSToolbarItem.Identifier> = {
        var identifiers: [NSToolbarItem.Identifier] = [
            .space,
            .flexibleSpace,
            .showColors,
            .showFonts,
            .print,
            .toggleSidebar,
            .cloudSharing,
            .separator,
            .customizeToolbar
        ]
        if #available(macOS 11.0, *) {
            identifiers.append(contentsOf: [.sidebarTrackingSeparator])
        }
        if #available(macOS 14.0, *) {
            identifiers.append(contentsOf: [.toggleInspector, .inspectorTrackingSeparator])
        }
        return .init(identifiers)
    }()
}

class ToolbarAdapter<Item: RxToolbarItemRepresentable>: NSObject, NSToolbarDelegate {
    public private(set) var items: [Item] = []

    private var _itemsMap: [NSToolbarItem.Identifier: Item] = [:]

    typealias ToolbarItemProvider = (NSToolbar, NSToolbarItem.Identifier, Bool, Item) -> NSToolbarItem?

    public var toolbarItemProvider: ToolbarItemProvider

    init(toolbarItemProvider: @escaping ToolbarItemProvider) {
        self.toolbarItemProvider = toolbarItemProvider
    }

    func setItems(_ items: [Item]) {
        self.items = items
        _itemsMap = [:]
        for item in items {
            _itemsMap[item.identifier] = item
        }
    }

    

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = _itemsMap[itemIdentifier], !SystemToolbarItemIdentifier.identifiers.contains(item.identifier) else { return nil }
        let toolbarItem = toolbarItemProvider(toolbar, itemIdentifier, flag, item)
        toolbarItem?.representedObject = item
        toolbarItem?.target = toolbar.rx.proxy
        toolbarItem?.action = #selector(RxNSToolbarProxy.run(_:))
        return toolbarItem
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isDefault).map(\.identifier)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isAllowed).map(\.identifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isSelectable).map(\.identifier)
    }
}

extension NSToolbar {
    func reloadData() {
        if !items.isEmpty {
            let items = items
            (0 ..< items.count).forEach { _ in removeItem(at: 0) }
            for (index, item) in items.enumerated() {
                insertItem(withItemIdentifier: item.itemIdentifier, at: index)
            }
        }

        let configuration = configuration
        setConfiguration([:])
        setConfiguration(configuration)
        validateVisibleItems()
    }
}

#endif
