#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSToolbar {
    public var delegate: DelegateProxy<NSToolbar, NSToolbarDelegate> {
        RxNSToolbarDelegateProxy.proxy(for: base)
    }

    public func items<Item: RxToolbarItemRepresentable, Source: ObservableType>(_ source: Source)
        -> (_ toolbarItemProvider: @escaping (_ toolbar: NSToolbar, _ itemIdentifier: NSToolbarItem.Identifier, _ willBeInsertedIntoToolbar: Bool, _ item: Item) -> NSToolbarItem?)
        -> Disposable where Source.Element == [Item] {
        return { toolbarItemProvider in
            let adapter = RxNSToolbarAdapter<Item>(toolbarItemProvider: toolbarItemProvider)
            return self.items(adapter: adapter)(source)
        }
    }

    public func items<Adpater: RxNSToolbarDelegateType & NSToolbarDelegate, Source: ObservableType>(adapter: Adpater)
        -> (_ source: Source)
        -> Disposable where Adpater.Element == Source.Element {
        return { source in
            let adapterSubscription = RxNSToolbarDelegateProxy.proxy(for: base).setRequiredMethodsDelegate(adapter)
            let subscription = source.asObservable()
                .observe(on: MainScheduler.instance)
                .catch { error in
                    bindingError(error)
                    return Observable.empty()
                }
                .concat(Observable.never())
                .take(until: base.rx.deallocated)
                .subscribe { [weak object = base] event in
                    guard let toolbar = object else { return }
                    adapter.toolbar(toolbar, observedEvent: event)
                    switch event {
                    case let .error(error):
                        bindingError(error)
                        adapterSubscription.dispose()
                    case .completed:
                        adapterSubscription.dispose()
                    default:
                        break
                    }
                }
            return Disposables.create {
                adapterSubscription.dispose()
                subscription.dispose()
            }
        }
    }
    
    var proxy: RxNSToolbarProxy {
        associatedValue { .init(toolbar: $0) }
    }
    
    public func itemAction<T>(_ itemType: T.Type) -> ControlEvent<(toolbarItem: NSToolbarItem, item: T)> {
        let source = proxy.didSelectItem.compactMap {
            if let item = $1 as? T {
                return (toolbarItem: $0, item: item)
            } else {
                return nil
            }
        }
        return ControlEvent(events: source)
    }
    
    public func itemAction<T>(_ itemType: T.Type) -> ControlEvent<T> {
        let source = proxy.didSelectItem.compactMap {
            if let item = $1 as? T {
                return item
            } else {
                return nil
            }
        }
        return ControlEvent(events: source)
    }
}

class RxNSToolbarProxy: NSObject, NSToolbarItemValidation {
    private unowned let toolbar: NSToolbar

    init(toolbar: NSToolbar) {
        self.toolbar = toolbar
        super.init()
    }

    let didSelectItem = PublishRelay<(NSToolbarItem, Any?)>()

    @objc func run(_ toolbarItem: NSToolbarItem) {
        didSelectItem.accept((toolbarItem, toolbarItem.representedObject))
    }
    
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        (item.representedObject as? RxToolbarItemRepresentable)?.shouldEnable ?? true
    }
}

extension NSToolbarItem {
    
    class RepresentedObjectWrapper: NSObject {
        var wrappedValue: Any?
        init(wrappedValue: Any? = nil) {
            self.wrappedValue = wrappedValue
        }
    }
    
    private static var representedObjectKey: Void = ()
    
    var representedObject: Any? {
        set {
            let wrapper = RepresentedObjectWrapper(wrappedValue: newValue)
            objc_setAssociatedObject(self, &Self.representedObjectKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let wrapper = objc_getAssociatedObject(self, &Self.representedObjectKey) as? RepresentedObjectWrapper else {
                return nil
            }
            return wrapper.wrappedValue
        }
    }
}

#endif
