#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@available(macOS 10.15, *)
class SharingServicePickerToolbarItemAdapter: NSObject, NSSharingServicePickerToolbarItemDelegate {
    
    var items: [Any] = []

    func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
        items
    }
}

#endif
