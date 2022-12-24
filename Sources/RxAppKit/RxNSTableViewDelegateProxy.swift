import Cocoa
import RxSwift
import RxCocoa

extension NSTableView: HasDelegate {
    public typealias Delegate = NSTableViewDelegate
}


public class RxNSTableViewDelegateProxy: DelegateProxy<NSTableView, NSTableViewDelegate>, DelegateProxyType, NSTableViewDelegate {
    public private(set) weak var tableView: NSTableView?
    
    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: RxNSTableViewDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        self.register { RxNSTableViewDelegateProxy(tableView: $0) }
    }
    
}

