import AppKit
import RxSwift
import RxCocoa

extension NSComboBox: @retroactive HasDataSource {
    public typealias Delegate = NSComboBoxDataSource
}

class RxNSComboBoxDataSourceProxy: DelegateProxy<NSComboBox, NSComboBoxDataSource>, DelegateProxyType, NSComboBoxDataSource {
    public private(set) weak var comboBox: NSComboBox?

    init(comboBox: NSComboBox) {
        self.comboBox = comboBox
        super.init(parentObject: comboBox, delegateProxy: RxNSComboBoxDataSourceProxy.self)
    }

    static func registerKnownImplementations() {
        register { RxNSComboBoxDataSourceProxy(comboBox: $0) }
    }

    private weak var _requiredMethodDataSource: NSComboBoxDataSource?

    override func setForwardToDelegate(_ delegate: DelegateProxy<NSComboBox, NSComboBoxDataSource>.Delegate?, retainDelegate: Bool) {
        _requiredMethodDataSource = delegate
        super.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    }

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        _requiredMethodDataSource?.numberOfItems?(in: comboBox) ?? 0
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        _requiredMethodDataSource?.comboBox?(comboBox, objectValueForItemAt: index)
    }
}
