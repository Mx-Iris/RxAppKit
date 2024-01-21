import AppKit
import RxSwift
import DifferenceKit

open class RxNSCollectionViewSectionedReloadDataSource<Section: DifferentiableSection>: CollectionViewSectionedDataSource<Section>, RxNSCollectionViewDataSourceType {
    public typealias Element = [Section]

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder<Element>(self) { dataSource, newSections in
            let oldSections = dataSource.sectionModels
            let changeset = StagedChangeset(source: oldSections, target: newSections)

            collectionView.reload(using: changeset) { _ in
                return true
            } setData: {
                dataSource.setSections($0)
            }
            collectionView.collectionViewLayout?.invalidateLayout()
        }.on(observedEvent)
    }
}

open class RxNSCollectionViewSectionedAnimatedDataSource<Section: DifferentiableSection>: CollectionViewSectionedDataSource<Section>, RxNSCollectionViewDataSourceType {
    public typealias Element = [Section]

    public typealias DecideViewTransition = (CollectionViewSectionedDataSource<Section>, NSCollectionView, Changeset<[Section]>) -> ViewTransition
    public var decideViewTransition: DecideViewTransition

    public init(
        decideViewTransition: @escaping DecideViewTransition = { _, _, _ in .animated },
        itemProvider: @escaping CollectionViewSectionedDataSource<Section>.ItemProvider,
        supplementaryViewProvider: @escaping CollectionViewSectionedDataSource<Section>.SupplementaryViewProvider = { _, _, _, _ in NSView() }
    ) {
        self.decideViewTransition = decideViewTransition
        super.init(itemProvider: itemProvider, supplementaryViewProvider: supplementaryViewProvider)
    }

    /// there is no longer limitation to load initial sections with reloadData
    /// but it is kept as a feature everyone got used to
    var dataSet = false

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder<Element>(self) { dataSource, newSections in
            if !dataSource.dataSet {
                dataSource.dataSet = true
                dataSource.setSections(newSections)
                collectionView.reloadData()
            } else {
                let oldSections = dataSource.sectionModels
                let changeset = StagedChangeset(source: oldSections, target: newSections)

                collectionView.reload(using: changeset) { changeset in
                    switch self.decideViewTransition(dataSource, collectionView, changeset) {
                    case .animated:
                        return false
                    case .reload:
                        return true
                    }
                } setData: {
                    dataSource.setSections($0)
                }
                collectionView.collectionViewLayout?.invalidateLayout()
            }
        }.on(observedEvent)
    }
}
