import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

/// Items
extension Reactive where Base: NSCollectionView {
    public func items<Item: Differentiable, Source: ObservableType>(_ source: Source)
        -> (_ itemProvider: @escaping (NSCollectionView, IndexPath, Item) -> NSCollectionViewItem)
        -> Disposable where Source.Element == [Item] {
        { itemProvider in
            let dataSource = RxNSCollectionViewArrayDataSource<Item>(itemProvider: itemProvider)
            return self.items(dataSource: dataSource)(source)
        }
    }
    
    public func items<Item: Differentiable, CollectionViewItem: NSCollectionViewItem, Source: ObservableType>(cellIdentifier: NSUserInterfaceItemIdentifier, cellType: CollectionViewItem.Type = CollectionViewItem.self)
        -> (_ source: Source)
        -> (_ configureCell: @escaping (IndexPath, Item, CollectionViewItem) -> Void)
        -> Disposable where Source.Element == [Item] {
        { source in
            { configureCell in
                let dataSource = RxNSCollectionViewArrayDataSource<Item> { cv, indexPath, item in
                    let cell = cv.makeItem(withIdentifier: cellIdentifier, for: indexPath) as! CollectionViewItem
                    configureCell(indexPath, item, cell)
                    return cell
                }

                return self.items(dataSource: dataSource)(source)
            }
        }
    }

    public func items<DataSource: RxNSCollectionViewDataSourceType & NSCollectionViewDataSource, Source: ObservableType>(dataSource: DataSource)
        -> (_ source: Source)
        -> Disposable where DataSource.Element == Source.Element {
        { source in
            // This is called for sideeffects only, and to make sure delegate proxy is in place when
            // data source is being bound.
            // This is needed because theoretically the data source subscription itself might
            // call `self.rx.delegate`. If that happens, it might cause weird side effects since
            // setting data source will set delegate, and NSCollectionView might get into a weird state.
            // Therefore it's better to set delegate proxy first, just to be sure.
            //			_ = self.delegate
            // Strong reference is needed because data source is in use until result subscription is disposed
            source.subscribeProxyDataSource(ofObject: self.base, dataSource: dataSource, retainDataSource: true) { [weak collectionView = self.base] (_: RxNSCollectionViewDataSourceProxy, event) in
                guard let collectionView else {
                    return
                }
                dataSource.collectionView(collectionView, observedEvent: event)
            }
        }
    }
}

///
extension Reactive where Base: NSCollectionView {
    public typealias DisplayCollectionViewItemEvent = (item: NSCollectionViewItem, at: IndexPath)
    public typealias DisplayCollectionViewSupplementaryViewEvent = (supplementaryView: NSView, elementKind: String, at: IndexPath)
    public typealias HighlightStateCollectionViewItemEvent = (indexPaths: Set<IndexPath>, to: NSCollectionViewItem.HighlightState)

    /// Reactive wrapper for `dataSource`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var dataSource: DelegateProxy<NSCollectionView, NSCollectionViewDataSource> {
        RxNSCollectionViewDataSourceProxy.proxy(for: base)
    }

    /// Installs data source as forwarding delegate on `rx.dataSource`.
    /// Data source won't be retained.
    ///
    /// It enables using normal delegate mechanism with reactive delegate mechanism.
    ///
    /// - parameter dataSource: Data source object.
    /// - returns: Disposable object that can be used to unbind the data source.
    public func setDataSource(_ dataSource: NSCollectionViewDataSource) -> Disposable {
        RxNSCollectionViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: base)
    }

    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<NSCollectionView, NSCollectionViewDelegate> {
        RxNSCollectionViewDelegateProxy.proxy(for: base)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didSelectItemsAt:)`
    public func itemSelected() -> ControlEvent<Set<IndexPath>> {
        let source = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:didSelectItemsAt:)))
            .map { a in
                try castOrThrow(Set<IndexPath>.self, a[1])
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didDeselectItemsAt:)`
    public func itemDeselected() -> ControlEvent<Set<IndexPath>> {
        let source = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:didDeselectItemsAt:)))
            .map { a in
                try castOrThrow(Set<IndexPath>.self, a[1])
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didChangeItemsAt:to:)`
    public func itemHighlightState() -> ControlEvent<HighlightStateCollectionViewItemEvent> {
        let source: Observable<HighlightStateCollectionViewItemEvent> = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:didChangeItemsAt:to:)))
            .map { a in
                try (
                    castOrThrow(Set<IndexPath>.self, a[1]),
                    castOrThrow(NSCollectionViewItem.HighlightState.self, a[2])
                )
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:willDisplay:forRepresentedObjectAt:)`
    public func willDisplayItem() -> ControlEvent<DisplayCollectionViewItemEvent> {
        let source: Observable<DisplayCollectionViewItemEvent> = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:willDisplay:forRepresentedObjectAt:)))
            .map { a in
                try (castOrThrow(NSCollectionViewItem.self, a[1]), castOrThrow(IndexPath.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:willDisplaySupplementaryView:forElementKind:at:)`
    public func willDisplaySupplementaryView() -> ControlEvent<DisplayCollectionViewSupplementaryViewEvent> {
        let source: Observable<DisplayCollectionViewSupplementaryViewEvent> = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:willDisplaySupplementaryView:forElementKind:at:)))
            .map { a in
                try (
                    castOrThrow(NSView.self, a[1]),
                    castOrThrow(String.self, a[2]),
                    castOrThrow(IndexPath.self, a[3])
                )
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didEndDisplaying:forRepresentedObjectAt:)`
    public func didEndDisplayingItem() -> ControlEvent<DisplayCollectionViewItemEvent> {
        let source: Observable<DisplayCollectionViewItemEvent> = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplaying:forRepresentedObjectAt:)))
            .map { a in
                try (castOrThrow(NSCollectionViewItem.self, a[1]), castOrThrow(IndexPath.self, a[2]))
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:)`
    public func didEndDisplayingSupplementaryView() -> ControlEvent<DisplayCollectionViewSupplementaryViewEvent> {
        let source: Observable<DisplayCollectionViewSupplementaryViewEvent> = delegate.methodInvoked(#selector(NSCollectionViewDelegate.collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:)))
            .map { a in
                try (
                    castOrThrow(NSView.self, a[1]),
                    castOrThrow(String.self, a[2]),
                    castOrThrow(IndexPath.self, a[3])
                )
            }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didSelectItemsAt:)`.
    ///
    /// It can be only used when one of the `rx.itemsWith*` methods is used to bind observable sequence,
    /// or any other data source conforming to `SectionedViewDataSourceType` protocol.
    ///
    /// ```
    ///     collectionView.rx.modelSelected(MyModel.self)
    ///        .map { ...
    /// ```
    public func modelSelected<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source: Observable<T> = itemSelected().flatMap { [weak view = self.base as NSCollectionView] indexPaths -> Observable<T> in
            guard let view, let indexPath = indexPaths.first else {
                return Observable.empty()
            }

            return try Observable.just(view.rx.model(at: indexPath))
        }

        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `collectionView(_:didSelectItemsAt)`.
    ///
    /// It can be only used when one of the `rx.itemsWith*` methods is used to bind observable sequence,
    /// or any other data source conforming to `SectionedViewDataSourceType` protocol.
    ///
    /// ```
    ///     collectionView.rx.modelDeselected(MyModel.self)
    ///        .map { ...
    /// ```
    public func modelDeselected<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source: Observable<T> = itemDeselected().flatMap { [weak view = self.base as NSCollectionView] indexPaths -> Observable<T> in
            guard let view, let indexPath = indexPaths.first else {
                return Observable.empty()
            }

            return try Observable.just(view.rx.model(at: indexPath))
        }

        return ControlEvent(events: source)
    }

    /// Synchronous helper method for retrieving a model at indexPath through a reactive data source
    public func model<T>(at indexPath: IndexPath) throws -> T {
        let dataSource: SectionedViewDataSourceType = castOrFatalError(dataSource.forwardToDelegate(), message: "This method only works in case one of the `rx.itemsWith*` methods was used.")

        let element = try dataSource.model(at: indexPath)

        return try castOrThrow(T.self, element)
    }
}

extension Reactive where Base: NSCollectionView {
    public func didScrollEnd(inSection section: Int) -> ControlEvent<DisplayCollectionViewItemEvent> {
        let source = willDisplayItem().filter {
            let numberOfItems = base.numberOfItems(inSection: section)
            return $1.item == numberOfItems - 1 && numberOfItems != 0
        }
        return ControlEvent(events: source)
    }
}
