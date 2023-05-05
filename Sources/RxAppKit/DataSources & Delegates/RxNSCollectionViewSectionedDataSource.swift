import AppKit
import RxSwift
import DifferenceKit

open class CollectionViewSectionedDataSource<Section: DifferentiableSection>: CollectionViewDataSource<Section.Collection.Element>, SectionedViewDataSourceType {
    public typealias Item = Section.Collection.Element

    public typealias Section = Section

    public typealias SectionModelSnapshot = ArraySection<Section, Item>

    private var _sectionModels: [SectionModelSnapshot] = []

    open var sectionModels: [Section] {
        return _sectionModels.map { Section(source: $0.model, elements: $0.elements) }
    }

    open subscript(section: Int) -> Section {
        let sectionModel = _sectionModels[section]
        return Section(source: sectionModel.model, elements: sectionModel.elements)
    }

    open subscript(indexPath: IndexPath) -> Item {
        get {
            return _sectionModels[indexPath.section].elements[indexPath.item]
        }
        set(item) {
            var section = _sectionModels[indexPath.section]
            section.elements[indexPath.item] = item
            _sectionModels[indexPath.section] = section
        }
    }

    open func model(at indexPath: IndexPath) throws -> Any {
        guard indexPath.section < _sectionModels.count,
              indexPath.item < _sectionModels[indexPath.section].elements.count else {
            throw RxDataSourceError.outOfBounds(indexPath: indexPath)
        }

        return self[indexPath]
    }

    open func setSections(_ sections: [Section]) {
        _sectionModels = sections.map { SectionModelSnapshot(model: $0, elements: $0.elements) }
    }

    open override func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return _sectionModels.count
    }

    open override func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return _sectionModels[section].elements.count
    }

    open override func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return itemProvider(collectionView, indexPath, self[indexPath])
    }
}

open class RxNSCollectionViewSectionedDataSource<Section: DifferentiableSection>: CollectionViewSectionedDataSource<Section>, RxNSCollectionViewDataSourceType {
    public typealias Element = [Section]

    public func collectionView(_ collectionView: NSCollectionView, observedEvent: Event<Element>) {
        Binder<Element>(self) { dataSource, newSections in
            let oldSections = dataSource.sectionModels
            let changeset = StagedChangeset(source: oldSections, target: newSections)

            collectionView.reload(using: changeset) {
                dataSource.setSections($0)
            }
        }.on(observedEvent)
    }
}
