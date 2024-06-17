#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

@available(macOS 10.15, *)
extension Reactive where Base: NSSharingServicePickerToolbarItem {
    private var _delegate: RxNSSharingServicePickerToolbarItemDelegateProxy {
        .proxy(for: base)
    }

    public var delegate: DelegateProxy<NSSharingServicePickerToolbarItem, NSSharingServicePickerToolbarItemDelegate> {
        _delegate
    }

    public func items<Source: ObservableType>(_ source: Source) -> Disposable where Source.Element == [Any] {
        return items(adapter: RxNSSharingServicePickerToolbarItemAdapter())(source)
    }

    public func items<Adapter: RxNSSharingServicePickerToolbarItemDelegateType & NSSharingServicePickerToolbarItemDelegate, Source: ObservableType>(adapter: Adapter) -> (_ source: Source) -> Disposable where Adapter.Element == Source.Element {
        return { source in
            source.subscribeProxyDataSource(ofObject: self.base, dataSource: adapter, retainDataSource: true) { [weak sharingServicePickerToolbarItem = base] (_: RxNSSharingServicePickerToolbarItemDelegateProxy, event) in
                guard let sharingServicePickerToolbarItem else { return }
                adapter.sharingServicePickerToolbarItem(sharingServicePickerToolbarItem, observedEvent: event)
            }
        }
    }
}

#endif
