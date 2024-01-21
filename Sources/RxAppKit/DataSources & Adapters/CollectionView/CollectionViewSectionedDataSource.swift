import AppKit

open class CollectionViewSectionedDataSource<Section: DifferentiableSection>: NSObject, NSCollectionViewDataSource, SectionedViewDataSourceType {
    public typealias Item = Section.Collection.Element
    public typealias Section = Section
    public typealias ItemProvider = (NSCollectionView, IndexPath, Item) -> NSCollectionViewItem
    public typealias SupplementaryViewProvider = (NSCollectionView, String, IndexPath, Section) -> (NSView)
    public typealias SectionModelSnapshot = ArraySection<Section, Item>

    open var itemProvider: ItemProvider
    open var supplementaryViewProvider: SupplementaryViewProvider
    private var _sectionModels: [SectionModelSnapshot] = []
    
    public init(
        itemProvider: @escaping ItemProvider,
        supplementaryViewProvider: @escaping SupplementaryViewProvider = { _, _, _, _ in NSView() }
    ) {
        self.itemProvider = itemProvider
        self.supplementaryViewProvider = supplementaryViewProvider
    }

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

    open func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return _sectionModels.count
    }

    open func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return _sectionModels[section].elements.count
    }

    open func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return itemProvider(collectionView, indexPath, self[indexPath])
    }
    
    public func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        return supplementaryViewProvider(collectionView, kind, indexPath, self[indexPath.section])
    }

}
