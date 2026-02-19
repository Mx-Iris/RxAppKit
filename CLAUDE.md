# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RxAppKit is a Swift Package that provides RxSwift reactive extensions for macOS AppKit controls. It fills the gap left by RxCocoa, which has rich iOS bindings but minimal macOS support. The library covers 40+ AppKit controls with `.rx` extensions, data source adapters, and delegate proxies.

- **Platforms**: macOS 10.13+
- **Swift**: 5.7+
- **Dependencies**: RxSwift/RxCocoa 6.6.0+, DifferenceKit 1.3.0+

## Build & Test Commands

```bash
# Build
swift build 2>&1 | xcsift

# Test
swift test 2>&1 | xcsift

# Build with Xcode (workspace includes example projects)
xcodebuild -workspace RxAppKit.xcworkspace -scheme RxAppKit -configuration Debug build 2>&1 | xcsift
```

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

**ISA-Swizzling** (`Common/ObjC+RuntimeSubclassing.swift`): Creates runtime subclasses for individual objects to intercept methods — technique borrowed from ReactiveCocoa.

**Reorderable Adapters**: For table views, `ReorderableTableViewArrayAdapter<T>` is a concrete subclass of `TableViewArrayAdapter` containing all reordering logic, with `RxNSTableViewReorderableDataSourceType` as its marker protocol. For outline views, `ReorderableOutlineViewAdapter<OutlineNode>` is a concrete subclass of `OutlineViewAdapter` containing all reordering logic, with `RxNSOutlineViewReorderableDataSourceType` as its marker protocol. Move events are emitted through `PublishSubject` via `_ItemMovedEventEmitting` / `_OutlineItemMovedEventEmitting` protocols.

### Adding a New Control Binding

1. Create `Components/NSFoo+Rx.swift` with `Reactive where Base: NSFoo` extension
2. If the control has a delegate/data source, create proxy class(es) in `Proxies/`
3. If the control needs a data source adapter, add a subdirectory under `DataSources & Adapters/`
4. Add any required marker protocols in `Protocols/`

### Tree Data (OutlineView)

`OutlineNodeType` protocol defines the tree interface (`parent`, `children`). `MutableOutlineNodeType` adds mutability. `OutlineViewAdapter` and `RxNSOutlineViewAdapter` handle the mapping from flat observable data to hierarchical NSOutlineView data source.
