import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSComboBox {
    func contents<Source: ObservableType>(_ source: Source) -> Disposable where Source.Element == [String] {
        return contents(dataSource: RxNSComboBoxDataSource())(source)
    }

    func contents<DataSource: RxNSComboBoxDataSourceType & NSComboBoxDataSource, Source: ObservableType>(dataSource: DataSource)
        -> (_ source: Source)
        -> Disposable where DataSource.Element == Source.Element {
        return { source in
            source.subscribeProxyDataSource(ofObject: self.base, dataSource: dataSource, retainDataSource: true) { [weak comboBox = base] (_: RxNSComboBoxDataSourceProxy, event) in
                guard let comboBox = comboBox else { return }
                dataSource.comboBox(comboBox, observedEvent: event)
            }
        }
    }

    var selectionDidChange: ControlEvent<Void> {
        controlEventForNotification(Base.selectionDidChangeNotification, object: base)
    }

    var selectionIsChanging: ControlEvent<Void> {
        controlEventForNotification(Base.selectionIsChangingNotification, object: base)
    }

    var willDismiss: ControlEvent<Void> {
        controlEventForNotification(Base.willDismissNotification, object: base)
    }

    var willPopUp: ControlEvent<Void> {
        controlEventForNotification(Base.willPopUpNotification, object: base)
    }
}
