import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSSegmentedControl {
    public var selectedSegmentIndex: ControlProperty<Int> {
        return _controlProperty(forKeyPath: \.selectedSegment)
    }

    /// Reactive wrapper for `setEnabled(_:forSegment:)`
    public func enabledForSegment(at index: Int) -> Binder<Bool> {
        return Binder(base) { segmentedControl, segmentEnabled in
            segmentedControl.setEnabled(segmentEnabled, forSegment: index)
        }
    }

    /// Reactive wrapper for `setLabel(_:forSegment:)`
    public func labelForSegment(at index: Int) -> Binder<String> {
        return Binder(base) { segmentedControl, title in
            segmentedControl.setLabel(title, forSegment: index)
        }
    }

    /// Reactive wrapper for `setImage(_:forSegment:)`
    public func imageForSegment(at index: Int) -> Binder<NSImage?> {
        return Binder(base) { segmentedControl, image in
            segmentedControl.setImage(image, forSegment: index)
        }
    }
}
