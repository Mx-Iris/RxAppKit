import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

public class RxNSCollectionViewArrayDataSource<Item: Differentiable>: CollectionViewArrayDataSource<Item>, RxNSCollectionViewDataSourceType {
    public typealias Element = [Item]

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder(self) { (dataSource: RxNSCollectionViewArrayDataSource<Item>, newItems: [Item]) in
            let oldItems = dataSource.items
            let newItems = newItems
            let changeset = StagedChangeset(source: oldItems, target: newItems)
            collectionView.reload(using: changeset) { _ in
                return true
            } setData: {
                dataSource.items = $0
            }
            collectionView.collectionViewLayout?.invalidateLayout()
        }.on(observedEvent)
    }

    
}
