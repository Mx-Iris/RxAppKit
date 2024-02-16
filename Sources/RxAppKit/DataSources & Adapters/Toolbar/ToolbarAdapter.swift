#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

open class ToolbarAdapter<Item: RxToolbarItemRepresentable>: NSObject, NSToolbarDelegate {
    public typealias ToolbarItemProvider = (NSToolbar, NSToolbarItem.Identifier, Bool, Item) -> NSToolbarItem?

    public internal(set) var items: [Item] = []

    private var _itemsMap: [NSToolbarItem.Identifier: Item] = [:]

    open var toolbarItemProvider: ToolbarItemProvider

    public init(toolbarItemProvider: @escaping ToolbarItemProvider) {
        self.toolbarItemProvider = toolbarItemProvider
    }

    open func setItems(_ items: [Item]) {
        self.items = items
        _itemsMap = [:]
        for item in items {
            _itemsMap[item.identifier] = item
        }
    }

    open func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = _itemsMap[itemIdentifier], !NSToolbarItem.systemIdentifiers.contains(item.identifier) else { return nil }
        let toolbarItem = toolbarItemProvider(toolbar, itemIdentifier, flag, item)
        toolbarItem?.representedObject = item
        toolbarItem?.target = toolbar.rx.proxy
        toolbarItem?.action = #selector(RxNSToolbarProxy.run(_:))
        return toolbarItem
    }

    open func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isDefault).map(\.identifier)
    }

    open func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isAllowed).map(\.identifier)
    }

    open func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        items.filter(\.isSelectable).map(\.identifier)
    }
}



#endif
