#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSToolbarItem {
    class RepresentedObjectWrapper: NSObject {
        var wrappedValue: Any?
        init(wrappedValue: Any? = nil) {
            self.wrappedValue = wrappedValue
        }
    }

    private static var representedObjectKey: Void = ()

    var representedObject: Any? {
        set {
            let wrapper = RepresentedObjectWrapper(wrappedValue: newValue)
            objc_setAssociatedObject(self, &Self.representedObjectKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let wrapper = objc_getAssociatedObject(self, &Self.representedObjectKey) as? RepresentedObjectWrapper else {
                return nil
            }
            return wrapper.wrappedValue
        }
    }
    
    static let systemIdentifiers: Set<NSToolbarItem.Identifier> = {
        var identifiers: [NSToolbarItem.Identifier] = [
            .space,
            .flexibleSpace,
            .showColors,
            .showFonts,
            .print,
            .toggleSidebar,
            .cloudSharing,
            .separator,
            .customizeToolbar,
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

#endif
