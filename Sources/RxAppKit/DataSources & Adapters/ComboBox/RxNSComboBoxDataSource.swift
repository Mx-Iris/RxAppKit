import AppKit
import RxSwift
import RxCocoa

open class RxNSComboBoxDataSource: ComboBoxDataSource, RxNSComboBoxDataSourceType {
    public typealias Element = [String]
    
    open func comboBox(_ comboBox: NSComboBox, observedEvent: Event<Element>) {
        Binder<[String]>(self) { dataSource, contents in
            dataSource.contents = contents
            comboBox.reloadData()
        }.on(observedEvent)
    }
}
