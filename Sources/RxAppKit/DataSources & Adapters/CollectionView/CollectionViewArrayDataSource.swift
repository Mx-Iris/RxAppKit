import AppKit

public class CollectionViewArrayDataSource<Item>: NSObject, NSCollectionViewDataSource, SectionedViewDataSourceType {
    public internal(set) var items: [Item] = []

    public typealias ItemProvider = (NSCollectionView, IndexPath, Item) -> NSCollectionViewItem
    public typealias SupplementaryViewProvider = (NSCollectionView, String, IndexPath) -> (NSView)

    open var itemProvider: ItemProvider
    open var supplementaryViewProvider: SupplementaryViewProvider

    public init(
        itemProvider: @escaping ItemProvider,
        supplementaryViewProvider: @escaping SupplementaryViewProvider = { _, _, _ in NSView() }
    ) {
        self.itemProvider = itemProvider
        self.supplementaryViewProvider = supplementaryViewProvider
    }
    
    public func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return itemProvider(collectionView, indexPath, items[indexPath.item])
    }
    
    public func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        return supplementaryViewProvider(collectionView, kind, indexPath)
    }
    
    public func model(at indexPath: IndexPath) throws -> Any {
        items[indexPath.item]
    }
}
