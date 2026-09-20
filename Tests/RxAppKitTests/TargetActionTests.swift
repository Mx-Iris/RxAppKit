import AppKit
import RxSwift
import RxCocoa
import Testing
@testable import RxAppKit

/// Covers the target-action bridge and the `@dynamicMemberLookup` surface it powers:
/// every writable property of a `HasTargeAction` conformer is reachable as a
/// `ControlProperty` without the library declaring it one by one.
@MainActor
@Suite("Target-action and dynamic member lookup")
final class TargetActionTests {
    private let window: NSWindow
    private let contentView: NSView

    init() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        self.window = window
        self.contentView = contentView
    }

    private func makeButton() -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        contentView.addSubview(button)
        return button
    }

    // MARK: - click

    @Test func clickEmitsOncePerInvocation() {
        let button = makeButton()
        var clickCount = 0
        let disposable = button.rx.click.subscribe(onNext: { clickCount += 1 })
        defer { disposable.dispose() }

        button.performClick(nil)
        button.performClick(nil)
        #expect(clickCount == 2)
    }

    @Test func clickStopsEmittingAfterDisposal() {
        let button = makeButton()
        var clickCount = 0
        let disposable = button.rx.click.subscribe(onNext: { clickCount += 1 })

        button.performClick(nil)
        #expect(clickCount == 1)

        disposable.dispose()
        button.performClick(nil)
        #expect(clickCount == 1)
    }

    /// Two subscribers on the same control must both see the click; the underlying
    /// forwarding target is shared, so dropping one must not silence the other.
    @Test func twoSubscribersBothSeeTheSameClick() {
        let button = makeButton()
        var firstCount = 0
        var secondCount = 0
        let firstDisposable = button.rx.click.subscribe(onNext: { firstCount += 1 })
        let secondDisposable = button.rx.click.subscribe(onNext: { secondCount += 1 })
        defer {
            firstDisposable.dispose()
            secondDisposable.dispose()
        }

        button.performClick(nil)
        #expect(firstCount == 1)
        #expect(secondCount == 1)
    }

    @Test func clickWithSelfCarriesTheControl() {
        let button = makeButton()
        var received: [NSButton] = []
        let disposable = button.rx.clickWithSelf.subscribe(onNext: { received.append($0) })
        defer { disposable.dispose() }

        button.performClick(nil)
        #expect(received.count == 1)
        #expect(received.first === button)
    }

    /// `click(with:)` reads a key path at the moment of the click, so it reports the
    /// value as of that click rather than as of subscription.
    @Test func clickWithKeyPathReadsTheValueAtClickTime() {
        let button = makeButton()
        button.title = "before"
        var received: [String] = []
        let disposable = button.rx.click(with: \.title).subscribe(onNext: { received.append($0) })
        defer { disposable.dispose() }

        button.performClick(nil)
        button.title = "after"
        button.performClick(nil)
        #expect(received == ["before", "after"])
    }

    @Test func clickWithKeyPathCanReplayTheCurrentValueFirst() {
        let button = makeButton()
        button.title = "initial"
        var received: [String] = []
        let disposable = button.rx.click(with: \.title, isStartWithDefaultValue: true)
            .subscribe(onNext: { received.append($0) })
        defer { disposable.dispose() }

        #expect(received == ["initial"])
        button.performClick(nil)
        #expect(received == ["initial", "initial"])
    }

    /// The control's own target/action must survive the interception — the proxy
    /// forwards, it does not take the slot over.
    @Test func anExistingTargetActionKeepsFiring() {
        final class ActionRecorder: NSObject {
            var invocations = 0
            @objc func handleAction(_ sender: Any?) { invocations += 1 }
        }

        let button = makeButton()
        let recorder = ActionRecorder()
        button.target = recorder
        button.action = #selector(ActionRecorder.handleAction(_:))

        var clickCount = 0
        let disposable = button.rx.click.subscribe(onNext: { clickCount += 1 })
        defer { disposable.dispose() }

        button.performClick(nil)
        #expect(recorder.invocations == 1)
        #expect(clickCount == 1)
    }

    // MARK: - dynamic member lookup as ControlProperty

    /// The headline feature: any writable property becomes a bindable sink without
    /// the library declaring it.
    @Test func bindingWritesThroughToTheControl() {
        let button = makeButton()
        let titles = PublishSubject<String>()
        let disposable = titles.bind(to: button.rx.title)
        defer { disposable.dispose() }

        titles.onNext("first")
        #expect(button.title == "first")
        titles.onNext("second")
        #expect(button.title == "second")
    }

    @Test func disposingABindingStopsWritingToTheControl() {
        let button = makeButton()
        let titles = PublishSubject<String>()
        let disposable = titles.bind(to: button.rx.title)

        titles.onNext("written")
        #expect(button.title == "written")

        disposable.dispose()
        titles.onNext("ignored")
        #expect(button.title == "written")
    }

    /// Different key paths must stay independent — binding one property must not
    /// write through to another.
    @Test func separateKeyPathsWriteToSeparateProperties() {
        let button = makeButton()
        button.title = "untouched"
        let states = PublishSubject<NSControl.StateValue>()
        let disposable = states.bind(to: button.rx.state)
        defer { disposable.dispose() }

        states.onNext(.on)
        #expect(button.state == .on)
        #expect(button.title == "untouched")
    }

    /// A `ControlProperty` read side reports the value as of each click, which is how
    /// a two-way binding picks up user-driven changes.
    @Test func readingAControlPropertyEmitsOnEveryClick() {
        let button = makeButton()
        button.title = "one"
        var received: [String] = []
        let property: ControlProperty<String> = button.rx.title
        let disposable = property.subscribe(onNext: { received.append($0) })
        defer { disposable.dispose() }

        button.performClick(nil)
        button.title = "two"
        button.performClick(nil)
        #expect(received == ["one", "two"])
    }

    /// The lookup works on non-`NSControl` conformers too — `NSMenuItem` carries
    /// target/action without being a control.
    @Test func theLookupReachesMenuItemsAsWell() {
        let menuItem = NSMenuItem()
        let titles = PublishSubject<String>()
        let disposable = titles.bind(to: menuItem.rx.title)
        defer { disposable.dispose() }

        titles.onNext("Menu Title")
        #expect(menuItem.title == "Menu Title")
    }
}
