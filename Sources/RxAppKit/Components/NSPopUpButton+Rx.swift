import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

extension String: Differentiable {}

public extension Reactive where Base: NSPopUpButton {
    var selectedItem: ControlEvent<String?> {
        controlEventForBaseAction { $0.selectedItem?.title }
    }

    func contents<Source: ObservableType>(source: Source) -> Disposable where Source.Element == [String] {
        return source.subscribe(with: base) { target, contents in
            if target.itemTitles.isEmpty {
                target.addItems(withTitles: contents)
            } else {
                let changeset = StagedChangeset(source: target.itemTitles, target: contents)
                changeset.forEach {
                    $0.elementInserted.forEach {
                        target.insertItem(withTitle: contents[$0.element], at: $0.element)
                    }
                    $0.elementDeleted.forEach {
                        target.removeItem(at: $0.element)
                    }
                    $0.elementMoved.forEach {
                        target.removeItem(at: $0.source.element)
                        target.insertItem(withTitle: contents[$0.target.element], at: $0.target.element)
                    }
                    $0.elementUpdated.forEach {
                        target.removeItem(at: $0.element)
                        target.insertItem(withTitle: contents[$0.element], at: $0.element)
                    }
                }
            }
        }
    }
}
