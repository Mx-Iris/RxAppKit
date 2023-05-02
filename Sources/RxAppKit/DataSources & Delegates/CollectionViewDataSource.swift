import AppKit
import DifferenceKit

open class CollectionViewDataSource<Item>: NSObject, NSCollectionViewDataSource {
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

    open func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    open func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        rxAbstractMethod()
    }

    open func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        supplementaryViewProvider(collectionView, kind, indexPath)
    }
}
