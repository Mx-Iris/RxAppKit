import AppKit
import RxSwift
import RxCocoa

open class RxNSSearchFieldDelegateProxy: RxNSTextFieldDelegateProxy, NSSearchFieldDelegate {
    public private(set) weak var searchField: NSSearchField?

    public init(searchField: NSSearchField) {
        self.searchField = searchField
        super.init(textField: searchField)
    }
}
