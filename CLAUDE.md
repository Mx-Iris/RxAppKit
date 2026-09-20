# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RxAppKit is a Swift Package that provides RxSwift reactive extensions for macOS AppKit controls. It fills the gap left by RxCocoa, which has rich iOS bindings but minimal macOS support. The library covers 40+ AppKit controls with `.rx` extensions, data source adapters, and delegate proxies.

- **Platforms**: macOS 12+ (the floor is AppKitPlus's — see the **AppKitPlus Trait** section)
- **Swift**: toolchain 6.2+, built in Swift 5 language mode (`swiftLanguageModes: [.v5]`)
- **Dependencies**: RxSwift/RxCocoa 6.6.0+, DifferenceKit 1.3.0+; AppKitPlus 0.4.2+ (optional, behind a default-off trait)

## Build & Test Commands

```bash
# Build
swift build 2>&1 | xcsift

# Build with the optional AppKitPlus trait on
swift build --traits AppKitPlus 2>&1 | xcsift

# Test. The verdict comes from swift test's own exit code, never from xcsift's summary:
# xcsift always exits 0 and can report a failing test as passing. zsh: ${pipestatus[1]},
# bash: ${PIPESTATUS[0]}.
swift test 2>&1 | xcsift; echo "swift test exit=${pipestatus[1]}"
swift test --traits AppKitPlus 2>&1 | xcsift; echo "swift test exit=${pipestatus[1]}"

# Build with Xcode (workspace includes example projects)
xcodebuild -workspace RxAppKit.xcworkspace -scheme RxAppKit -configuration Debug build 2>&1 | xcsift
```

A clean run is **106 tests, 0 issues, exit code 0**, with or without the trait. The suite was
red from May to September 2026 (a regression plus one test that never matched its
implementation); if it goes red again, it is your change.

## AppKitPlus Trait

`AppKitPlus` is an optional SPM trait, **off by default**. It links
[AppKitPlus](https://github.com/AppKitSupportProgram/AppKitPlus-Release) — a binary framework that
ports modern UIKit API shapes (content configurations, diffable data sources, cell registration,
trait collections, block animation) onto AppKit.

**Nothing in RxAppKit uses it yet.** The trait is a conduit for `.rx` bindings still to come. Its
only source-level presence is `Sources/RxAppKit/Common/AppKitPlus.swift`, which imports the module
so upstream name collisions fail *this* build rather than a consumer's, and which exposes
`RxAppKitTraits.isAppKitPlusEnabled`. AppKitPlus is deliberately **not** re-exported.

Three parts to the contract:

- **The package's macOS floor is AppKitPlus's, not RxAppKit's.** AppKitPlus ships as a
  `binaryTarget` requiring macOS 12, and SwiftPM checks that on the package graph — before any
  source is compiled, and regardless of `@available` or `#if`. Keeping the floor at 10.13 builds
  fine with the trait off but fails the moment anyone turns it on, with an error naming *this*
  package's manifest, which a consumer cannot edit. Hence macOS 12 unconditionally.
- **Trait off costs nothing.** SwiftPM neither clones the repository nor downloads the
  xcframework. `Package.resolved` must not contain `appkitplus-release` — if it does, a
  trait-on build wrote it; revert that file before committing.
- **Every AppKitPlus version bump needs a name-collision recheck.** Upstream promises no API or
  ABI stability and adds categories to `NSTableView`, `NSOutlineView`, `NSCollectionView`,
  `NSControl`, `NSButton`, `NSMenuItem`, `NSToolbarItem`, `NSWindow`, `NSEvent`, `NSCell`,
  `NSView` and `NSViewController`. A category member whose name matches a property declared by a
  *subclass* is an illegal override in Swift rather than a shadowing: it fails the build, and the
  constraint propagates to downstream modules that never import AppKitPlus. This library has zero
  collisions as of 0.4.2 — the version constraint is `from:`, so re-run
  `swift build --traits AppKitPlus` after every bump to keep that true.

Background and the measurements behind each point:
`Documentations/Evolutions/0001-appkitplus-trait.md`.

## Architecture

### Source Layout (`Sources/RxAppKit/`)

| Directory | Purpose |
|---|---|
| `Common/` | ObjC runtime helpers (ISA-swizzling, method interception), delegate proxy infrastructure, associated object wrappers |
| `Components/` | `NSControl+Rx.swift` style extensions — each file adds `.rx` properties to one AppKit class |
| `Proxies/` | `DelegateProxy` subclasses (e.g. `RxNSTableViewDataSourceProxy`) that intercept delegate/data source calls and forward to both Rx streams and native delegates |
| `DataSources & Adapters/` | Concrete data source/delegate implementations per control (TableView, OutlineView, CollectionView, Browser, Toolbar, etc.) |
| `Protocols/` | Marker protocols (`RxNSTableViewDataSourceType`, `RxNSOutlineViewDataSourceType`, etc.) and reorderable adapter protocols |
| `Target-Action/` | NSControl target-action to Rx bridging |

### Supporting Targets

- **`RxAppKitObjC`** (`Sources/RxAppKitObjC/`): Objective-C runtime aliases for message forwarding and associated objects — required because Swift cannot call these APIs directly.

### Key Design Patterns

**Delegate Proxy Pattern**: Each AppKit delegate/data source has a corresponding `DelegateProxy` subclass in `Proxies/`. These intercept native delegate calls and expose them as Rx observables while supporting `RequiredMethodDelegateProxyType` to handle required delegate methods via `_requiredMethodsDelegate` container.

**Data Source Adapter Pattern**: Adapters in `DataSources & Adapters/` serve as both `NSTableViewDataSource` and `NSTableViewDelegate` (or equivalent). They hold the items array and a `cellProvider` closure. Rx-specific wrappers (e.g. `RxNSTableViewArrayReloadAdapter`, `RxNSTableViewArrayAnimatedAdapter`) subscribe to Observable sequences and use DifferenceKit's `StagedChangeset` for efficient diffing updates.

**Never ask `==` whether the model changed.** Node and item types here implement `Equatable` on
identity alone — `NSOutlineView` only keeps a row expanded across an update when the new item is
`==` to the old one, so that is the required shape, not a shortcut. It means `==` and
`Differentiable.isContentEqual` deliberately disagree: two structurally different trees with the
same ids are `==`. Any "has anything changed?" check must therefore go through the diffing
semantics (`StagedChangeset` being empty, or `differenceIdentifier` plus `isContentEqual`), never
through `==`. A short-circuit that got this wrong silently swallowed every content-only update —
subtree adds and removes simply did nothing — for four commits before the tests were read.

**ISA-Swizzling** (`Common/ObjC+RuntimeSubclassing.swift`): Creates runtime subclasses for individual objects to intercept methods — technique borrowed from ReactiveCocoa.

**Reorderable Adapters**: For table views, `ReorderableTableViewArrayAdapter<T>` is a concrete subclass of `TableViewArrayAdapter` containing all reordering logic, with `RxNSTableViewReorderableDataSourceType` as its marker protocol. For outline views, `ReorderableOutlineViewAdapter<OutlineNode>` is a concrete subclass of `OutlineViewAdapter` containing all reordering logic, with `RxNSOutlineViewReorderableDataSourceType` as its marker protocol. Move events are emitted through `PublishSubject` via `_ItemMovedEventEmitting` / `_OutlineItemMovedEventEmitting` protocols.

### Adding a New Control Binding

1. Create `Components/NSFoo+Rx.swift` with `Reactive where Base: NSFoo` extension
2. If the control has a delegate/data source, create proxy class(es) in `Proxies/`
3. If the control needs a data source adapter, add a subdirectory under `DataSources & Adapters/`
4. Add any required marker protocols in `Protocols/`

### Tree Data (OutlineView)

`OutlineNodeType` protocol defines the tree interface (`parent`, `children`). `MutableOutlineNodeType` adds mutability. `OutlineViewAdapter` and `RxNSOutlineViewAdapter` handle the mapping from flat observable data to hierarchical NSOutlineView data source.
