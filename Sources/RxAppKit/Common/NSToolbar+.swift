#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

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
