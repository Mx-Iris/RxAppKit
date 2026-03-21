import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension String: @retroactive ContentEquatable {}
extension String: @retroactive ContentIdentifiable {}

extension Reactive where Base: NSPopUpButton {
    public func selectedItem() -> ControlEvent<String?> {
        _controlEventForBaseAction { $0.selectedItem?.title }
    }

    public func selectedItemIndex() -> ControlEvent<Int> {
        _controlEventForBaseAction { $0.indexOfSelectedItem }
    }
    
    public func selectedIndex() -> ControlProperty<Int> {
        _controlProperty { base in
            base.indexOfSelectedItem
        } setter: { base, selectedIndex in
            base.selectItem(at: selectedIndex)
        }
    }

    public func items() -> Binder<[String]> {
        Binder(base) { (target: NSPopUpButton, items: [String]) in
            if target.itemTitles.isEmpty {
                items.forEach(target.addItem(withTitle:))
            } else {
                let changeset = StagedChangeset(source: target.itemTitles, target: .init(items))
                changeset.forEach {
                    $0.elementInserted.forEach {
                        target.insertItem(withTitle: items[$0.element], at: $0.element)
                    }

                    $0.elementDeleted
                        .map { target.itemTitles[$0.element] }
                        .forEach { target.removeItem(withTitle: $0) }

                    $0.elementMoved.forEach {
                        target.removeItem(at: $0.source.element)
                        target.insertItem(withTitle: items[$0.target.element], at: $0.target.element)
                    }

                    $0.elementUpdated.forEach {
                        target.removeItem(at: $0.element)
                        target.insertItem(withTitle: items[$0.element], at: $0.element)
                    }
                }
            }
        }
    }

//    func contents<Source: ObservableType>(source: Source) -> Disposable where Source.Element == [String] {
//        return source.subscribe(with: base) { target, contents in
//            if target.itemTitles.isEmpty {
//                target.addItems(withTitles: contents)
//            } else {
//                let changeset = StagedChangeset(source: target.itemTitles, target: contents)
//                changeset.forEach {
//                    $0.elementInserted.forEach {
//                        target.insertItem(withTitle: contents[$0.element], at: $0.element)
//                    }
//
//                    $0.elementDeleted
//                        .map { target.itemTitles[$0.element] }
//                        .forEach { target.removeItem(withTitle: $0) }
//
//                    $0.elementMoved.forEach {
//                        target.removeItem(at: $0.source.element)
//                        target.insertItem(withTitle: contents[$0.target.element], at: $0.target.element)
//                    }
//
//                    $0.elementUpdated.forEach {
//                        target.removeItem(at: $0.element)
//                        target.insertItem(withTitle: contents[$0.element], at: $0.element)
//                    }
//                }
//            }
//        }
//    }
}

@available(macOS 14.0, *)
extension Reactive where Base: NSPopUpButton {
    /// Binds section-grouped items to a popup button using NSMenuItem.sectionHeader.
    public func sectionItems<Section, Item>(
        sectionTitle: @escaping (Section) -> String,
        items: @escaping (Section) -> [Item],
        itemTitle: @escaping (Item) -> String,
        itemImage: ((Item) -> NSImage?)? = nil,
        itemRepresentedObject: @escaping (Item) -> AnyHashable
    ) -> Binder<[Section]> {
        Binder(base) { popUpButton, sections in
            let previousRepresentedObject = popUpButton.selectedItem?.representedObject as? AnyHashable

            popUpButton.menu?.removeAllItems()

            for section in sections {
                let header = NSMenuItem.sectionHeader(title: sectionTitle(section))
                popUpButton.menu?.addItem(header)

                for item in items(section) {
                    let menuItem = NSMenuItem(title: itemTitle(item), action: nil, keyEquivalent: "")
                    menuItem.image = itemImage?(item)
                    menuItem.representedObject = itemRepresentedObject(item)
                    popUpButton.menu?.addItem(menuItem)
                }
            }

            // Restore selection by representedObject (skip section headers)
            if let previousRepresentedObject {
                let index = popUpButton.menu?.items.firstIndex {
                    ($0.representedObject as? AnyHashable) == previousRepresentedObject
                }
                if let index {
                    popUpButton.selectItem(at: index)
                }
            } else {
                // Select first item that has a representedObject (i.e. not a section header)
                let index = popUpButton.menu?.items.firstIndex { $0.representedObject != nil }
                if let index {
                    popUpButton.selectItem(at: index)
                }
            }
        }
    }
}

extension Reactive where Base: NSPopUpButton {
    /// Emits the representedObject of the selected item when selection changes.
    public func selectedItemRepresentedObject<T: Hashable>(_ type: T.Type = T.self) -> ControlEvent<T?> {
        _controlEventForBaseAction { $0.selectedItem?.representedObject as? T }
    }
}
