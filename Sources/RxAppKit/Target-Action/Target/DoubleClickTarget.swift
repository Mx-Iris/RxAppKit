import RxSwift
import Foundation

/// This should be only used from `MainScheduler`
final class DoubleClickTarget: RxTarget {
    typealias Callback = () -> Void

    let selector: Selector = #selector(doubleActionHandler)

    var callback: Callback?

    init(callback: @escaping Callback) {
        MainScheduler.ensureRunningOnMainThread()
        self.callback = callback
    }

    @objc func doubleActionHandler() {
        callback?()
    }

    override func dispose() {
        super.dispose()
        callback = nil
    }
}
