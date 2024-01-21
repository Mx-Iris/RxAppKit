import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension String: Differentiable {}

extension Reactive where Base: NSPopUpButton {
    public var selectedItem: ControlEvent<String?> {
        _controlEventForBaseAction { $0.selectedItem?.title }
    }

    public var selectedIndex: ControlProperty<Int> {
        _controlProperty { base in
            base.indexOfSelectedItem
        } setter: { base, selectedIndex in
            base.selectItem(at: selectedIndex)
        }
    }

    public var items: Binder<[String]> {
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
