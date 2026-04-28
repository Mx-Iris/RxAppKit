---
name: rxappkit-bindings
description: Use when writing or reviewing AppKit UI bound with RxSwift through RxAppKit — connecting NSButton/NSControl actions, binding NSOutlineView/NSTableView/NSCollectionView data sources, or driving view visibility (isHidden) and other state from Rx streams. Triggers especially when about to declare `PublishRelay<Void>()` + `@objc` action wiring, or hand-roll an `NSOutlineViewDataSource` / `NSOutlineViewDelegate` for data already produced by an Rx pipeline.
---

# RxAppKit Bindings

RxAppKit ships first-class Rx bindings for almost every AppKit control and for `NSOutlineView` / `NSTableView` / `NSCollectionView` data sources. **Do not roll your own.** Hand-wired `PublishRelay`/`@objc` plumbing and bespoke `NSOutlineViewDataSource` implementations are a code smell — the framework already provides the Rx surface.

Apply these rules whenever you touch an AppKit ViewController that uses RxSwift.

## Rules

### 1. `Reactive` is `@dynamicMemberLookup` — use `rx.<anyProperty>` directly

`RxSwift.Reactive<Base>` is declared `@dynamicMemberLookup`. By default it synthesizes a `Binder<Property>` (write-only) for any writable reference key path on the base.

**RxAppKit overrides this for every `HasTargeAction` conformer with two more subscripts** (from `HasTargeAction+Rx.swift`):

```swift
extension Reactive where Base: HasTargeAction {
    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Property>) -> ControlProperty<Property>
    @_disfavoredOverload
    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, Property>) -> ControlEvent<Property>
}
```

**Conformers shipped by RxAppKit:** `NSControl` (and every subclass: `NSButton`, `NSTextField`, `NSPopUpButton`, `NSSlider`, `NSStepper`, `NSColorWell`, `NSSegmentedControl`, …), `NSMenuItem`, `NSToolbarItem`, `NSGestureRecognizer`, `NSColorPanel`.

That means **every writable property on these types is automatically reachable through `rx.<name>` as a `ControlProperty`** — driven by the underlying target/action. You almost never need to write an explicit binder by hand:

```swift
// ✅ All of these work without RxAppKit defining an explicit accessor for the property
output.title.drive(button.rx.title)              // Driver<String> → button title
button.rx.state.asObservable()                    // emits NSControl.StateValue on each click
popUpButton.rx.indexOfSelectedItem.asSignal()     // emits new selection index
slider.rx.doubleValue.asSignal()                  // emits slider value while dragging
menuItem.rx.title.asSignal()                      // observe menu item title via menu action
toolbarItem.rx.label.asSignal()
```

`ControlProperty` is the default overload (`ControlEvent` is `@_disfavoredOverload` and only resolves when the call site explicitly demands it). `ControlProperty` already conforms to `ObservableType` and `ObserverType`, so you can `.asSignal()`, `.asObservable()`, `.drive(...)`, etc.

**Convenience accessors for the void-action case** (you only care that an action fired, not which property changed):

- `control.rx.click: ControlEvent<Void>`
- `control.rx.clickWithSelf: ControlEvent<Self>` — emits the control instance
- `control.rx.click(with: keyPath, isStartWithDefaultValue:)` — emits the value at that keyPath each click

```swift
// ✅ GOOD — wire button actions through rx.click / rx.<property>
let input = ViewModel.Input(
    cancelAll: cancelAllButton.rx.click.asSignal(),
    openSettings: openSettingsButton.rx.click.asSignal(),
    isExpanded: disclosureButton.rx.state.map { $0 == .on }.asSignal(onErrorJustReturn: false)
)

// Local-only actions (no ViewModel involvement)
closeButton.rx.click.asSignal()
    .emit(onNext: { [weak self] in
        self?.dismiss(nil)
    })
    .disposed(by: disposeBag)
```

```swift
// ❌ BAD — relay + @objc plumbing duplicates what rx already provides
private let cancelAllRelay = PublishRelay<Void>()
private let openSettingsRelay = PublishRelay<Void>()

private func setupActions() {
    cancelAllButton.target = self
    cancelAllButton.action = #selector(cancelAllClicked)
    openSettingsButton.target = self
    openSettingsButton.action = #selector(openSettingsClicked)
}

@objc private func cancelAllClicked()    { cancelAllRelay.accept(()) }
@objc private func openSettingsClicked() { openSettingsRelay.accept(()) }

let input = ViewModel.Input(
    cancelAll: cancelAllRelay.asSignal(),
    openSettings: openSettingsRelay.asSignal()
)
```

`rx.click` returns `ControlEvent<Void>`. Call `.asSignal()` before chaining `emit(onNext:)` / before passing to a `Signal`-typed `Input` field.

**Heuristic:** before defining a `PublishRelay`, a `Binder`, or a manual `target/action`, type `control.rx.` and let auto-complete show you what's already synthesized — for any `HasTargeAction` conformer the answer is "all of its writable properties".

### 2. Bind list/tree views via RxAppKit data sources — never write `NSXxxDataSource`/`Delegate` by hand

For every list/tree view, RxAppKit ships an Rx data-source binding that owns the underlying `NSXxxDataSource` + `NSXxxDelegate` proxy and the diffing pipeline. Pick the right one by view type:

| View | Primary binding | Element protocol | Provider signature |
|------|------------------|------------------|---------------------|
| `NSTableView` | `tableView.rx.items(_:)` / `.reorderableItems(_:)` / `.items(adapter:)` | `Differentiable` | `(NSTableView, NSTableColumn?, Int, Item) -> NSView?` |
| `NSOutlineView` | `outlineView.rx.nodes` / `.rootNode` / `.reorderableNodes` / `.nodes(adapter:)` | `OutlineNodeType & Hashable & Differentiable` | `(NSOutlineView, NSTableColumn?, Node) -> NSView?` |
| `NSCollectionView` | `collectionView.rx.items(_:)` / `.items(cellIdentifier:cellType:)` / `.items(dataSource:)` | `Differentiable` | `(NSCollectionView, IndexPath, Item) -> NSCollectionViewItem` |
| `NSBrowser` | `browser.rx.rootNode(cellClass:)` / `.rootNode(adapter:)` | `BrowserNodeType` | `(Node, Cell, row: Int, column: Int) -> Void` |

`Differentiable` is satisfied automatically for `Hashable & Equatable` types — override `differenceIdentifier` only when content mutations should keep the same row identity (e.g. progress updates inside an enum case).

#### NSTableView

```swift
// ✅ GOOD — single-column or multi-column table
output.items
    .drive(tableView.rx.items) { (tableView: NSTableView, column: NSTableColumn?, row: Int, item: Item) -> NSView? in
        let cell = (tableView.makeView(withIdentifier: .nameCell, owner: nil) as? NameCellView) ?? NameCellView()
        cell.configure(item: item)
        return cell
    }
    .disposed(by: disposeBag)

// Add a row-view provider when needed (selection styling, separators, etc.)
output.items
    .drive(tableView.rx.items) ({ tableView, _, _, item in … },
                                { tableView, row, items in MyRowView() })
    .disposed(by: disposeBag)
```

Reorderable variant: `tableView.rx.reorderableItems(_:)` registers internal drag-and-drop. Sync the upstream relay via `tableView.rx.modelMoved()` (emits the new array) or `rx.itemMoved()` (emits source/destination indexes).

Other table events: `rx.itemSelected()`, `rx.itemClicked()`, `rx.itemDoubleClicked()`, `rx.modelSelected()`, `rx.didAddRow()`, `rx.didRemoveRow()`, `rx.didClickColumn()`, `rx.didDragColumn()`, `rx.didScrollEnd()`.

#### NSOutlineView

The element type must conform to `OutlineNodeType & Hashable & Differentiable`. `OutlineNodeType` only requires `var children: [Self] { get }`.

```swift
// ✅ GOOD — model conforms to OutlineNodeType + Differentiable
enum MyNode: Hashable {
    case section(Section, items: [MyNode])
    case item(Item)
}

extension MyNode: OutlineNodeType {
    var children: [MyNode] {
        switch self {
        case .section(_, let items): return items
        case .item: return []
        }
    }
}

extension MyNode: Differentiable {
    enum Identifier: Hashable {
        case section(Section.ID)
        case item(Item.ID)
    }
    var differenceIdentifier: Identifier {
        switch self {
        case .section(let s, _): return .section(s.id)
        case .item(let i):       return .item(i.id)
        }
    }
}

output.nodes
    .drive(outlineView.rx.nodes) { (outlineView: NSOutlineView, _: NSTableColumn?, node: MyNode) -> NSView? in
        switch node {
        case .section(let section, _):
            let cell = (outlineView.makeView(withIdentifier: .sectionCell, owner: nil) as? SectionCellView) ?? SectionCellView()
            cell.configure(section: section)
            return cell
        case .item(let item):
            let cell = (outlineView.makeView(withIdentifier: .itemCell, owner: nil) as? ItemCellView) ?? ItemCellView()
            cell.configure(item: item)
            return cell
        }
    }
    .disposed(by: disposeBag)
```

Use `rx.rootNode(source:)` when the source emits a single root node, `rx.reorderableNodes` for drag-and-drop trees. Selection events: `rx.modelSelected()`, `rx.modelClicked()`, `rx.modelDoubleClicked()`. Reorder events: `rx.nodeMoved()` (full `OutlineMove`), `rx.modelMoved()` (new root array).

**Drive form:** `output.nodes.drive(outlineView.rx.nodes) { … }` works through RxSwift's `drive(_:curriedArgument:)` overload — `outlineView.rx.nodes` is a function reference of type `(Observable) -> (CellViewProvider) -> Disposable`, the trailing closure is the cell view provider.

**Do not subclass `OutlineViewAdapter` "to force reloadData".** `RxNSOutlineViewAdapter.outlineView(_:observedEvent:)` already passes `interrupt: { _ in true }` to `reload(using:)`, which falls back to `outlineView.reloadData()` on every event. The default binding *is* a full reload.

If you need to expand all rows after each update, attach a separate subscription to the same Driver:

```swift
output.nodes.drive(onNext: { [weak self] _ in
    self?.outlineView.expandItem(nil, expandChildren: true)
})
.disposed(by: disposeBag)
```

#### NSCollectionView

Three binding flavours, in order of convenience:

```swift
// ✅ GOOD — `cellIdentifier:cellType:` form: dequeue + configure in one closure
output.items
    .bind(to: collectionView.rx.items(cellIdentifier: .photoCell, cellType: PhotoCollectionViewItem.self)) { (indexPath, item, cell) in
        cell.configure(photo: item)
    }
    .disposed(by: disposeBag)

// Or supply your own item provider when you need full control over dequeue
output.items
    .bind(to: collectionView.rx.items) { (collectionView, indexPath, item) -> NSCollectionViewItem in
        let cell = collectionView.makeItem(withIdentifier: .photoCell, for: indexPath) as! PhotoCollectionViewItem
        cell.configure(photo: item)
        return cell
    }
    .disposed(by: disposeBag)

// Or, for sectioned data, plug a custom data source through `rx.items(dataSource:)`.
```

Selection / display events: `rx.itemSelected()`, `rx.itemDeselected()`, `rx.modelSelected(MyModel.self)`, `rx.modelDeselected(_:)`, `rx.itemHighlightState()`, `rx.willDisplayItem()`, `rx.didEndDisplayingItem()`, `rx.didScrollEnd(inSection:)`, plus the supplementary-view variants.

#### NSBrowser

`NSBrowser` uses its own `BrowserNodeType` protocol (note: distinct from `OutlineNodeType`) — requires `var title: String` and `var children: [NodeType]`.

```swift
struct FileNode: BrowserNodeType {
    let title: String
    var children: [FileNode]
}

// rx.rootNode is doubly curried: (cellClass:) → (source) → (configureCell)
output.fileTree
    .drive(browser.rx.rootNode(cellClass: NSBrowserCell.self)) { (node: FileNode, cell: NSBrowserCell, row: Int, column: Int) in
        cell.title = node.title
        cell.isLeaf = node.isLeaf
    }
    .disposed(by: disposeBag)
```

Click / selection events: `rx.clickedIndex` / `rx.doubleClicked` (return `(row: Int, column: Int)`), `rx.selectedIndexPath`. Path control: `rx.path: ControlProperty<String>` — both observable and bindable.

#### Anti-pattern: hand-rolled data source for any of the above

```swift
// ❌ BAD — re-implementing what rx.nodes / rx.items already does
private var renderedNodes: [MyNode] = []

extension MyViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int { ... }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any { ... }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool { ... }
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? { ... }
}

output.nodes.drive(onNext: { [weak self] nodes in
    self?.renderedNodes = nodes
    self?.outlineView.reloadData()
})
.disposed(by: disposeBag)
```

The same anti-pattern applies to writing `NSTableViewDataSource`, `NSCollectionViewDataSource`, or `NSBrowserDelegate` by hand when the data already lives in an Rx stream.

### 3. Drive view state through `rx.isHidden` / `rx.stringValue` / etc. — never assign in a closure

```swift
// ✅ GOOD — declarative bindings
output.isEnabled.drive(view.rx.isHidden).disposed(by: disposeBag)
output.hasFailure.map(!).drive(button.rx.isHidden).disposed(by: disposeBag)
output.subtitle.drive(subtitleLabel.rx.stringValue).disposed(by: disposeBag)

Driver.combineLatest(output.isEnabled, output.hasItems) { enabled, hasItems in
    !enabled || !hasItems
}
.drive(scrollView.rx.isHidden)
.disposed(by: disposeBag)
```

```swift
// ❌ BAD — imperative assignment buried inside a closure
output.isEnabled.drive(onNext: { [weak self] enabled in
    self?.view.isHidden = enabled
    self?.button.isHidden = enabled
})
.disposed(by: disposeBag)

Observable.combineLatest(output.isEnabled.asObservable(), output.hasItems.asObservable())
    .subscribe(onNext: { [weak self] enabled, hasItems in
        self?.scrollView.isHidden = !enabled || !hasItems
    })
    .disposed(by: disposeBag)
```

`Driver.combineLatest(_:_:resultSelector:)` is the right tool for combined visibility logic. Negate a `Driver<Bool>` with `.map(!)`.

## Imports

```swift
import RxSwift
import RxCocoa
import RxAppKit  // also re-exports DifferenceKit, so `Differentiable` is accessible
```

`RxAppKit` does **not** re-export `RxSwift` or `RxCocoa` — import them explicitly.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `let xxxRelay = PublishRelay<Void>()` + `@objc func xxxClicked()` for a button | `button.rx.click.asSignal()` (Rule 1) |
| Defining an explicit `Binder<Property>` / `ControlProperty` for a property already on a `HasTargeAction` type | Just call `control.rx.<propertyName>` — `@dynamicMemberLookup` already synthesizes it (Rule 1) |
| `closeButton.rx.click.emit(onNext:)` (compile error: `ControlEvent` has no `emit`) | `rx.click` is `ControlEvent<Void>` — call `.asSignal()` first |
| Hand-rolled `NSTableViewDataSource` / `NSOutlineViewDataSource` / `NSCollectionViewDataSource` / `NSBrowserDelegate` for data already in an Rx stream | Bind through `tableView.rx.items` / `outlineView.rx.nodes` / `collectionView.rx.items` / `browser.rx.rootNode` (Rule 2) |
| Subclassing `OutlineViewAdapter` "so we get reloadData" | The default adapter's `interrupt` closure already triggers `reloadData()` (Rule 2) |
| Keeping a `private var renderedNodes: [Node]` / `private var rows: [Item]` on the ViewController | Let the adapter own it; the Driver is the source of truth |
| Confusing `OutlineNodeType` with `BrowserNodeType` | They are separate protocols — `BrowserNodeType` requires `var title: String` plus `children` |
| `view.isHidden = …` inside a `drive(onNext:)` closure | `output.isEnabled.drive(view.rx.isHidden)` (Rule 3) |
| Manual `target = self` / `action = #selector(...)` for any control with an Rx wrapper | Use the `rx.*` extension instead |
