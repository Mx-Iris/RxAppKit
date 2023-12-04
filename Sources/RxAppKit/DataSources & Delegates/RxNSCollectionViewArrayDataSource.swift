import AppKit
import RxSwift
import RxCocoa

public class CollectionViewArrayDataSource<Sequence: Swift.Sequence>: CollectionViewDataSource<Sequence.Element> {
    public typealias Item = Sequence.Element
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

public class RxNSCollectionViewArrayDataSource<Sequence: Swift.Sequence>: CollectionViewArrayDataSource<Sequence>, RxNSCollectionViewDataSourceType, SectionedViewDataSourceType {
    public typealias Element = Sequence

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder<[Sequence.Element]>(self) { dataSource, items in
            dataSource.items = items
            collectionView.reloadData()
        }.on(observedEvent.map(Array.init))
    }
    
    public func model(at indexPath: IndexPath) throws -> Any {
        items[indexPath.item]
    }
}
