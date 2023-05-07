import AppKit
import RxSwift
import RxCocoa

extension NSCollectionView: RxCocoa.HasDelegate {
    public typealias Delegate = NSCollectionViewDelegate
}

class RxNSCollectionViewDelegateProxy: DelegateProxy<NSCollectionView, NSCollectionViewDelegate>, DelegateProxyType, NSCollectionViewDelegate {
    public private(set) weak var collectionView: NSCollectionView?

    public init(collectionView: ParentObject) {
        self.collectionView = collectionView
        super.init(parentObject: collectionView, delegateProxy: RxNSCollectionViewDelegateProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSCollectionViewDelegateProxy(collectionView: $0) }
    }
}
