import AppKit
import RxSwift
import RxCocoa

extension NSCollectionView: HasDataSource {
    public typealias DataSource = NSCollectionViewDataSource
}

private let collectionViewDataSourceNotSet = CollectionViewDataSourceNotSet()

private final class CollectionViewDataSourceNotSet: NSObject, NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        rxAbstractMethod(message: dataSourceNotSet)
    }
}

/// For more information take a look at `DelegateProxyType`.
class RxNSCollectionViewDataSourceProxy: DelegateProxy<NSCollectionView, NSCollectionViewDataSource>, DelegateProxyType, NSCollectionViewDataSource {
    /// Typed parent object.
    public private(set) weak var collectionView: NSCollectionView?

    /// - parameter collectionView: Parent object for delegate proxy.
    public init(collectionView: ParentObject) {
        self.collectionView = collectionView
        super.init(parentObject: collectionView, delegateProxy: RxNSCollectionViewDataSourceProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        register { RxNSCollectionViewDataSourceProxy(collectionView: $0) }
    }

    private weak var _requiredMethodsDataSource: NSCollectionViewDataSource? = collectionViewDataSourceNotSet

    // MARK: delegate

    /// Required delegate method implementation.
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        (_requiredMethodsDataSource ?? collectionViewDataSourceNotSet).collectionView(collectionView, numberOfItemsInSection: section)
    }

    /// Required delegate method implementation.
    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        (_requiredMethodsDataSource ?? collectionViewDataSourceNotSet).collectionView(collectionView, itemForRepresentedObjectAt: indexPath)
    }

    /// For more information take a look at `DelegateProxyType`.
    open override func setForwardToDelegate(_ delegate: NSCollectionViewDataSource?, retainDelegate: Bool) {
        _requiredMethodsDataSource = delegate ?? collectionViewDataSourceNotSet
        super.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    }
}
