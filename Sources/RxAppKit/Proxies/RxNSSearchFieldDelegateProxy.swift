import AppKit
import RxSwift
import RxCocoa

class RxNSSearchFieldDelegateProxy: RxNSTextFieldDelegateProxy, NSSearchFieldDelegate {
    public private(set) weak var searchField: NSSearchField?

    public init(searchField: NSSearchField) {
        self.searchField = searchField
        super.init(textField: searchField)
    }
}
