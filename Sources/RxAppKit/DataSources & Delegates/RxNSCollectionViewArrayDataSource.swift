import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

public class CollectionViewArrayDataSource<Item>: CollectionViewDataSource<Item> {
    public var items: [Item] = []

    public override func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    public override func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public override func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return itemProvider(collectionView, indexPath, items[indexPath.item])
    }
}

public class RxNSCollectionViewArrayDataSource<Item: Hashable>: CollectionViewArrayDataSource<Item>, RxNSCollectionViewDataSourceType, SectionedViewDataSourceType {
    public typealias Element = [Item]

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder(self) { (dataSource: RxNSCollectionViewArrayDataSource<Item>, newItems: [Item]) in
            let oldItems = dataSource.items.map { AnyDifferentiable($0) }
            let newItems = newItems.map { AnyDifferentiable($0) }
            let changeset = StagedChangeset(source: oldItems, target: newItems)
            collectionView.reload(using: changeset) {
                dataSource.items = $0.map { $0.base }
            }
        }.on(observedEvent)
    }
    
    public func model(at indexPath: IndexPath) throws -> Any {
        items[indexPath.item]
    }
}
