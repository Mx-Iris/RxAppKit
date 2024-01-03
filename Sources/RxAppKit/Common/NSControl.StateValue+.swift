#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension NSControl.StateValue {
    init(boolValue: Bool) {
        self = boolValue ? .on : .off
    }

    func boolValue(isMixedEqualTrue: Bool) -> Bool {
        switch self {
        case .on:
            true
        case .off:
            false
        case .mixed:
            isMixedEqualTrue ? true : false
        default:
            false
        }
    }
}

#endif
