import RxSwift
import Foundation

/// This should be only used from `MainScheduler`
class BaseTarget: RxTarget {
    typealias Callback = () -> Void

    let selector = #selector(baseActionHandler)

    var callback: Callback?

    init(callback: @escaping Callback) {
        self.callback = callback
        super.init()
    }

    @objc func baseActionHandler() {
        callback?()
    }

    override func dispose() {
        super.dispose()
        callback = nil
    }
}
