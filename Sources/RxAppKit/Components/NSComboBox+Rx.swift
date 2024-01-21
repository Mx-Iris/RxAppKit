import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSComboBox {
    public func contents<Source: ObservableType>(_ source: Source) -> Disposable where Source.Element == [String] {
        return contents(dataSource: RxNSComboBoxDataSource())(source)
    }

    public func contents<DataSource: RxNSComboBoxDataSourceType & NSComboBoxDataSource, Source: ObservableType>(dataSource: DataSource)
        -> (_ source: Source)
        -> Disposable where DataSource.Element == Source.Element {
        return { source in
            source.subscribeProxyDataSource(ofObject: self.base, dataSource: dataSource, retainDataSource: true) { [weak comboBox = base] (_: RxNSComboBoxDataSourceProxy, event) in
                guard let comboBox else { return }
                dataSource.comboBox(comboBox, observedEvent: event)
            }
        }
    }

    public var selectionDidChange: ControlEvent<Void> {
        controlEventForNotification(Base.selectionDidChangeNotification, object: base)
    }

    public var selectionIsChanging: ControlEvent<Void> {
        controlEventForNotification(Base.selectionIsChangingNotification, object: base)
    }

    public var willDismiss: ControlEvent<Void> {
        controlEventForNotification(Base.willDismissNotification, object: base)
    }

    public var willPopUp: ControlEvent<Void> {
        controlEventForNotification(Base.willPopUpNotification, object: base)
    }
}
