import AppKit
import RxSwift
import RxCocoa

extension Reactive where Base: NSTextView {
    public var attributedString: ControlProperty<NSAttributedString?> {
        let source: Observable<NSAttributedString?> = Observable.deferred { [weak textView = self.base] in
            let attributedText = textView?.attributedString()

            let textChanged: Observable<NSAttributedString?> = textView?.textStorage?
                // This project uses text storage notifications because
                // that's the only way to catch autocorrect changes
                // in all cases. Other suggestions are welcome.
                .rx.didProcessEditingRangeChangeInLength
                // This observe on is here because attributedText storage
                // will emit event while process is not completely done,
                // so rebinding a value will cause an exception to be thrown.
                .observe(on: MainScheduler.asyncInstance)
                .map { _ in
                    textView?.attributedString()
                }
                ?? Observable.empty()

            return textChanged
                .startWith(attributedText)
        }

        let bindingObserver = Binder(base) { (textView, attributedString: NSAttributedString?) in
            // This check is important because setting text value always clears control state
            // including marked text selection which is important for proper input
            // when IME input method is used.
            if textView.attributedString() != attributedString, let attributedString {
                textView.textStorage?.setAttributedString(attributedString)
            }
        }

        return ControlProperty(values: source, valueSink: bindingObserver)
    }

    public var didBeginEditing: ControlEvent<Void> {
        controlEventForNotification(Base.didBeginEditingNotification, object: base)
    }

    public var didEndEditing: ControlEvent<Void> {
        controlEventForNotification(Base.didEndEditingNotification, object: base)
    }

    public var didChange: ControlEvent<Void> {
        controlEventForNotification(Base.didChangeNotification, object: base)
    }
}
