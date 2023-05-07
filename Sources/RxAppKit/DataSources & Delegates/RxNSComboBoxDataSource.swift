import AppKit
import RxSwift
import RxCocoa

class RxNSComboBoxDataSource: ComboBoxDataSource, RxNSComboBoxDataSourceType {
    typealias Element = [String]
    func comboBox(_ comboBox: NSComboBox, observedEvent: Event<Element>) {
        Binder<[String]>(self) { dataSource, contents in
            dataSource.contents = contents
            comboBox.reloadData()
        }.on(observedEvent)
    }
}
