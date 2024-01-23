#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit


class ObjectContainer<Object: AnyObject> {
    
    private enum ReferenceType {
        case weak
        case strong
        case empty
    }
    
    private weak var weakObject: Object?
    private var strongObject: Object?
    private var type: ReferenceType
    
    init() {
        self.type = .empty
    }
    
    init(weakObject: Object) {
        self.weakObject = weakObject
        self.type = .weak
    }
    init(strongObject: Object) {
        self.strongObject = strongObject
        self.type = .strong
    }
    
    func setWeakObject(_ object: Object) {
        weakObject = nil
        strongObject = nil
        type = .weak
        weakObject = object
    }
    
    func setStrongObject(_ object: Object) {
        weakObject = nil
        strongObject = nil
        type = .strong
        strongObject = object
    }
    
    func setObject(_ object: Object?) {
        guard let object else {
            weakObject = nil
            strongObject = nil
            return
        }
        switch type {
        case .weak:
            self.weakObject = object
        case .strong:
            self.strongObject = object
        default:
            break
        }
    }
    
    var object: Object? {
        switch type {
        case .weak:
            return weakObject
        case .strong:
            return strongObject
        case .empty:
            return nil
        }
    }
}

#endif
