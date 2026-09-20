# 0001 - AppKitPlus：以默认关闭的 SPM trait 接入可选依赖

- **状态**: Implemented
- **作者**: JH
- **创建日期**: 2026-09-20
- **最后更新**: 2026-09-20
- **所属愿景**: 无
- **关联提案**: 无（本仓库第一份提案）。跨仓库参考：UIFoundation 的 `0017-appkitplus-layer-backed-view.md`
- **实现分支 / PR**: `main`（直接落地）
- **配套文档**: 无 —— 调用方契约写在 `CLAUDE.md` 的「AppKitPlus Trait」一节与 `README.md`

## 摘要

把 [AppKitPlus](https://github.com/AppKitSupportProgram/AppKitPlus-Release) 接成 RxAppKit 的可选依赖，
门控在一个新的、默认关闭的 SPM trait `AppKitPlus` 下。

本次**只建通道，不走货**：trait 开启时 RxAppKit 真的 `import AppKitPlus`（让上游挂在 AppKit 类上的
category 对本库全部源码可见，从而把命名冲突暴露在编译期），并暴露一个编译期常量
`RxAppKitTraits.isAppKitPlusEnabled` 供下游查询自己拿到的是哪一个构建；trait 关闭时 SwiftPM 连仓库
都不 clone，默认消费者成本为零。**不为 AppKitPlus 的任何类型编写 `.rx` 绑定** —— 那是后续提案的事。

代价是两条破坏性变更：包级 macOS 下限 **10.13 → 12**，swift-tools-version **5.7 → 6.2**。

## 动机

### 两个库的重叠面已经足够大

AppKitPlus 把 UIKit 的现代 API 形态移植到 AppKit。与本库直接重叠或互补的部分：

| AppKitPlus | 本库对应物 | 关系 |
|---|---|---|
| `NSOutlineViewDiffableDataSource`、`NSTableViewDiffableReorderableDataSource` | `Sources/RxAppKit/DataSources & Adapters/` 下用 DifferenceKit 手写的那套 | 职责重叠 |
| `NSOutlineViewCellRegistration`、`NSTableViewCellRegistration`、`NSCollectionViewItemRegistration` | 各 adapter 里的 `cellProvider` 闭包 | 职责重叠 |
| `NSAction`、`NSActionBindable` | `Sources/RxAppKit/Target-Action/` | 职责重叠 |
| `NSCalendarView`、`NSModernDrawer`、`NSDragInteraction` / `NSDropInteraction`、`NSFocusSystem`、`NSTraitChangeObservable` | 无 | 本库尚无 `.rx` 绑定的新控件与新事件源 |

这些绑定是否要做、怎么做、trait 开启时要不要换实现，**每一个都是独立的决定，本提案一个都不做**。
但它们全都要先有一条依赖通道。

### 为什么通道要单独落一批

通道本身带两条破坏性变更（平台下限、工具链下限）。把它们与第一个绑定混在同一批，那一批的 diff 会
同时包含破坏性改动与新功能：既无法单独回退，也无法单独验证真正的风险 —— **AppKitPlus 挂在 AppKit
类上的 category，与本库密集的 `.rx` 扩展是否撞名**。

这个风险有先例，不是理论上的：UIFoundation 接入同一依赖时撞到三处，其中两处是编译期直接失败的
非法 override（`error: overriding non-open property outside of its defining module`），且那条命名
约束会传染给从不 `import AppKitPlus` 的下游模块。详见前期调研第 4 条。

### 为什么是现在，而不是等到要用的时候

平台下限与工具链下限改一次，所有下游就要同步一次 —— 早改比晚改便宜。更实际的一条：现在改，可以
拿本库**既有的全部源码**当冲突检测样本。这是能拿到的最大一次样本，以后每加一个绑定，样本只会更小。

## 前期调研

所有实测在本机完成：macOS 26 / Swift 6.3.3 工具链（`swiftlang-6.3.3.1.3`）/ AppKitPlus-Release 0.4.2。
探针是 `/tmp/claude/probe/RxAppKit`（本仓库的一份临时拷贝，非仓库产物），构建产物在
`/tmp/claude/SwiftPM/` 下。

### 1. UIFoundation 的接法

`Package.swift` 里声明一个默认关闭的 trait，target 用 `condition: .when(traits: ["AppKitPlus"])`
条件依赖 `AppKitPlus-Release` 的 product，源码用 `#if AppKitPlus && canImport(AppKitPlus)` 分叉。
`AppKitPlus-Release` 是一个只含 `binaryTarget` 的 manifest，指向 GitHub Release 上的
`AppKitPlus.xcframework.zip`，其包级 `platforms` 声明 `.macOS(.v12)`。

UIFoundation 同时把包级 macOS 下限从 10.15 抬到了 12，并在注释里记「二进制 target 的平台要求是在
包依赖图上检查的」。本提案第 2 条把这个结论测得更精确。

### 2. 平台下限：不抬，就是交付一个「一开就炸」的死开关

两组探针实测：

| 探针配置 | 结果 |
|---|---|
| `platforms: [.macOS(.v10_13)]` + trait 关闭 | **构建通过**（`Build complete!`） |
| `platforms: [.macOS(.v10_13)]` + `--traits AppKitPlus` | **构建失败** |

失败时的报错原文：

```
error: the library 'RxAppKit' requires macos 10.13, but depends on the product 'AppKitPlus'
which requires macos 12.0; consider changing the library 'RxAppKit' to require macos 12.0 or
later, or the product 'AppKitPlus' to require macos 10.13 or earlier.
```

两条结论：

- **trait 关闭时，保持 10.13 是可行的** —— 因为 AppKitPlus 根本不进依赖图（见第 3 条）。所以
  「不抬 floor」在默认路径上不会立刻出问题。
- **但 trait 一开就失败，而且失败在消费者那边、指向的是本库的 manifest**（"consider changing the
  library 'RxAppKit' to require macos 12.0 or later"）—— 消费者改不了别人的 manifest，只能放弃这个
  trait。那等于交付一个标称可用、实际一开就炸的开关。

这是显式抬 floor 的理由：**把代价摆在 manifest 上，而不是埋在消费者的构建日志里。**
`@available` 与 `#if AppKitPlus` 都绕不过去 —— 这是包依赖图层面的检查，发生在任何一行源码被编译
之前；拆 target 也没用，`platforms` 是包级声明。

### 3. trait 关闭时，SwiftPM 完全不碰这个依赖

删掉 `Package.resolved` 后分别解析：

| 构建 | `Package.resolved` 里的 pins |
|---|---|
| `swift build`（trait 关闭） | `differencekit`、`rxswift` |
| `swift build --traits AppKitPlus` | `differencekit`、`rxswift`、**`appkitplus-release`** |

trait 关闭时不 clone 仓库、不下载 xcframework。**默认消费者为这个依赖付出的成本是零**（除去 floor
抬升本身）。

### 4. 命名冲突面：实测为零

trait 开启的干净构建（`rm -rf` scratch 后重跑）：**0 error**，警告集合与 trait 关闭时**逐条相同**：

```
warning: 'customizeToolbar' was deprecated in macOS 11.0 …
warning: 'separator' was deprecated in macOS 11.0 …
warning: left side of nil coalescing operator '??' has non-optional type 'NSMenu' …
```

也就是说，AppKitPlus 0.4.2 加在 `NSTableView` / `NSOutlineView` / `NSCollectionView` / `NSControl` /
`NSButton` / `NSMenuItem` / `NSToolbarItem` / `NSWindow` / `NSEvent` / `NSCell` / `NSView` /
`NSViewController` 上的 category 成员，与本库现有全部源码**没有一处撞名**，也没有一处改变既有重载
决议（上面三条警告在 trait 关闭时同样存在，不是新引入的）。

**为什么是零，而 UIFoundation 不是** —— 这不是运气，是两个库的形状不同：

- 本库的扩展几乎全部活在 `Reactive` 命名空间下（`base.rx.xxx`），不直接给 AppKit 类添加同名成员。
  对 AppKit 类的直接 extension 只有 20 余处，且绝大多数是协议遵循（`extension NSTableView: HasDelegate`）
  而非新增属性。
- 本库基本不子类化 `NSTableCellView` / `NSCollectionViewItem` / `NSViewController` —— 全仓库只有两个
  私有子类（`CollectionViewSectionedDataSource.swift:3` 的 `EmptySupplementaryView`、
  `RxNSPageControllDelegateProxy.swift:10` 的 `ViewController`），都不声明与上游 category 同名的属性。
  而 UIFoundation 那三处冲突全部来自子类声明了同名属性（`contentView`、`parent`、
  `navigationController`）。

**这条结论有保质期。** 上游自述无 API/ABI 稳定性保证，每发一个 minor 都可能在新的 AppKit 类上挂
category。**每次升级 AppKitPlus 版本，都必须重跑一次 `swift build --traits AppKitPlus` 复查冲突面**，
不因为版本约束写的是 `from:` 就自动安全。

### 5. 测试基线：main 上有 4 个既有失败

`swift test` 在三种配置下跑出的结果完全一致：**40 tests / 5 suites / 7 issues**，退出码 1。

| 配置 | 结果 |
|---|---|
| 当前仓库原样（tools 5.7 / macOS 10.13） | 40 tests, 7 issues |
| 探针 trait 关闭 | 40 tests, 7 issues |
| 探针 trait 开启 | 40 tests, 7 issues |

失败的测试：`rootNodeAdapterSubtreeUpdate()`、`subtreeAddChildPropagates()`、
`subtreeRemoveChildPropagates()`（`RxNSOutlineViewAdapter` suite）、
`topLevelItemsAreSectionGroupItems()`（`RxNSOutlineViewSectionedAdapter` suite）。

**这些是本次改动之前就存在的失败，本提案既不修复也不加重。** 记录在此是为了让落地时的验证有一个
明确的基线：落地后仍应是 40 tests / 7 issues，且失败集合不变；多一个或少一个都说明本次改动有副作用。
修这 4 个测试是独立议题。

### 6. 抬下限会新增 2 条废弃警告

`Sources/RxAppKit/Common/NSToolbarItem+.swift:37-38` 引用了 `NSToolbarItem.Identifier.separator` 与
`.customizeToolbar`，两者自 macOS 11.0 起废弃。部署目标为 10.13 时编译器不报（部署目标低于废弃版本），
抬到 12 之后各报一条。

这是抬 floor 的直接副作用，与 AppKitPlus 本身无关。本次不处理，理由见「非目标」。

## 提议方案

1. **新增 SPM trait `AppKitPlus`**，默认关闭（不进 `defaultTraits`）。
2. **新增依赖** `https://github.com/AppKitSupportProgram/AppKitPlus-Release`，约束 `from: "0.4.2"`。
   注意 SwiftPM 的 `from:` 对 0.x 也是 up-to-next-major（`0.4.2 ..< 1.0.0`），因此 0.5.0 这类可能带
   破坏性变更的版本会被自动取用 —— 配套要求见前期调研第 4 条末尾的复查约定。
3. **`RxAppKit` target 条件依赖它**：`.product(name: "AppKitPlus", package: "AppKitPlus-Release",
   condition: .when(traits: ["AppKitPlus"]))`。本包只支持 macOS 一个平台，因此不需要再写
   `platforms:` 条件。
4. **包级 `platforms` 的 macOS 项由 `.v10_13` 改为 `.v12`**。
5. **swift-tools-version 由 5.7 改为 6.2**，并显式声明 `swiftLanguageModes: [.v5]`。后者不是可选的：
   tools-version 一旦 ≥ 6.0，默认语言模式就变成 Swift 6，会把严格并发检查整个打开 —— 那是一笔与本
   提案无关的技术债。
6. **新增一个 canary 文件** `Sources/RxAppKit/Common/AppKitPlus.swift`：trait 开启时真的
   `import AppKitPlus`，并暴露 `RxAppKitTraits.isAppKitPlusEnabled`。它的作用是让「trait 开启」这条
   路径有真实的编译覆盖 —— 不 import 的话，上游 category 对本库源码不可见，trait 开与关在编译层面
   完全等价，前期调研第 4 条那个结论就根本测不出来。
7. **新增测试** `Tests/RxAppKitTests/AppKitPlusTraitTests.swift`，固定 trait 状态常量与编译条件一致。

### 非目标

- **不为 AppKitPlus 的任何类型编写 `.rx` 绑定。** 动机一节那张表里的每一项都是独立提案。
- **不改动现有 adapter 的实现。** trait 开启时 `DataSources & Adapters/` 下的代码一行不变，不切换到
  `NSOutlineViewDiffableDataSource` / `NSTableViewDiffableReorderableDataSource`。
- **不 `@_exported import AppKitPlus`。** 下游想用 AppKitPlus 的 API 自己加依赖、自己 import。把别人
  的 API 表面挂到本库名下，会让本库的公开表面随上游版本漂移。
- **不碰三个示例工程**（`Examples/NSTableView-Example` / `NSOutlineView-Example` / `NSBrowser-Example`）。
  本次零使用代码，示例工程开了 trait 也没有任何东西可验证。它们的部署目标已是 13.x，不受 floor 抬升
  影响。
- **不清理源码里那 13 处 `@available(macOS 10.15/11.0/14.0, *)` 与 `#available` 判断。** 抬 floor 后
  其中 9 处（10.15 ×8、11.0 ×1）在逻辑上变成恒真，但实测编译器一条警告都不产生，清理纯属可读性收益，
  属独立技术债，混进来只会让本次 diff 无法审查。
- **不处理前期调研第 6 条那 2 条新增的废弃警告。** 消除它们要么改变 `systemIdentifiers` 集合的内容
  （行为改变），要么把符号引用换成硬编码字符串（可靠性下降），两条都是独立决定。
- **不修前期调研第 5 条那 4 个既有失败测试。**
- **不引入 UIFoundation 那个 `.package(local:remote:)` 本地/远程切换 helper。** 本机
  `/Volumes/Repositories/Private/Personal/Library/macOS/AppKitPlus-Release` 只是同一份 `binaryTarget`
  manifest（内容就是一个指向 GitHub Release 的 URL 加 checksum），挂上去零收益；真正的 AppKitPlus
  源码工程是 Xcode 工程而非 SwiftPM 包，无法作为本地 path 依赖。
- **不加 CI。** 本仓库目前没有 `.github/workflows`，补 CI 是独立议题 —— 但值得单独提一句：本提案引入
  的「两条构建路径」正是 CI 最该固定的东西。

## 详细设计

### `Package.swift`

```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RxAppKit",
    // macOS 12 is AppKitPlus's own floor. A binary target's platform requirement is
    // checked on the package graph, so neither `@available` nor `#if AppKitPlus` can
    // keep this at 10.13 while the trait is available — see the `AppKitPlus` proposal.
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "RxAppKit",
            targets: ["RxAppKit"]
        ),
    ],
    traits: [
        .trait(name: "AppKitPlus"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveX/RxSwift",
            .upToNextMajor(from: "6.6.0")
        ),
        .package(
            url: "https://github.com/ra1028/DifferenceKit",
            .upToNextMajor(from: "1.3.0")
        ),
        // 0.4.2 is a floor, not a pin. Upstream promises no API/ABI stability, so every
        // version bump needs a `swift build --traits AppKitPlus` to recheck the naming
        // conflict surface.
        .package(
            url: "https://github.com/AppKitSupportProgram/AppKitPlus-Release",
            from: "0.4.2"
        ),
    ],
    targets: [
        .target(
            name: "RxAppKit",
            dependencies: [
                "RxAppKitObjC",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "DifferenceKit", package: "DifferenceKit"),
                .product(
                    name: "AppKitPlus",
                    package: "AppKitPlus-Release",
                    condition: .when(traits: ["AppKitPlus"])
                ),
            ]
        ),

        .target(
            name: "RxAppKitObjC"
        ),

        .testTarget(
            name: "RxAppKitTests",
            dependencies: ["RxAppKit"]
        ),
    ],
    // Required, not optional: a tools-version of 6.0 or later defaults to the Swift 6
    // language mode, which would turn on strict concurrency checking across the package.
    swiftLanguageModes: [.v5]
)
```

### `Sources/RxAppKit/Common/AppKitPlus.swift`

```swift
#if AppKitPlus && canImport(AppKitPlus)
// Imported for its effect on the module, not for any symbol used below: it makes
// AppKitPlus's categories on NSTableView / NSOutlineView / NSCollectionView / NSControl
// and friends visible to every file in this target, so a name collision between an
// upstream category member and one of this library's extensions fails the build here
// rather than in a consumer's. Without this import the `AppKitPlus` trait would have no
// observable effect on compilation at all.
import AppKitPlus
#endif

/// Compile-time facts about which optional pieces of RxAppKit this build contains.
///
/// SwiftPM traits are resolved when the package graph is built, so a consumer cannot tell
/// from the outside whether the copy of RxAppKit it linked against was built with the
/// `AppKitPlus` trait on. These constants make that answer available at the call site.
public enum RxAppKitTraits {
    /// Whether this build of RxAppKit was compiled with the `AppKitPlus` package trait enabled.
    ///
    /// Enable it from a consuming package with
    /// `.package(url: ..., traits: ["AppKitPlus"])`, or from the command line with
    /// `swift build --traits AppKitPlus`.
    public static let isAppKitPlusEnabled: Bool = {
        #if AppKitPlus && canImport(AppKitPlus)
        true
        #else
        false
        #endif
    }()
}
```

文件放在 `Common/` 下，与既有的库级入口 `Common/RxAppKit.swift`（公开 typealias 的归集处）并列。

### `Tests/RxAppKitTests/AppKitPlusTraitTests.swift`

```swift
import Testing
@testable import RxAppKit

@Suite("AppKitPlus trait")
struct AppKitPlusTraitTests {
    /// The trait flag must agree with the condition the module was actually compiled under.
    @Test func traitFlagMatchesCompilationCondition() {
        #if AppKitPlus && canImport(AppKitPlus)
        #expect(RxAppKitTraits.isAppKitPlusEnabled)
        #else
        #expect(!RxAppKitTraits.isAppKitPlusEnabled)
        #endif
    }
}
```

这个测试本身断言的内容很轻 —— 它真正的价值在别处：测试 target 依赖 `RxAppKit`，而 `RxAppKit` 在 trait
开启时 import 了 AppKitPlus，隐式传递可见性会让测试 target 也编译在「上游 category 可见」的前提下。
**UIFoundation 实测过这条传染路径**：一个从不 `import AppKitPlus` 的下游模块，照样会因为子类里的同名
属性而编译失败。所以这个测试文件是下游视角的第二个 canary，覆盖的是本库源码覆盖不到的那一半。

## 替代方案考量

- **另开一个独立包 `RxAppKitPlus`**（下限 12 / tools 6.2，依赖 RxAppKit + AppKitPlus），RxAppKit 本体
  保持 10.13 / tools 5.7 一动不动。否决理由：一个仓库只能有一份 `Package.swift`，这条路意味着新建并
  长期维护第二个仓库；而跨包写 `.rx` 扩展会撞上 `internal` 可见性 —— 本库大量基础设施
  （`ObjC+RuntimeSubclassing`、各 `DelegateProxy` 的内部钩子、`RequiredMethodsDelegateProxyType`）
  都不是 public，新包要么拿不到，要么逼本库把它们全部公开，那是比抬 floor 大得多的 API 表面变动。
- **无条件依赖，不用 trait。** tools-version 可以少抬一档，源码里不用写 `#if` 分叉。否决：所有消费者
  都被迫下载 xcframework 并链接一个用不到的二进制框架，而本次连一行使用代码都没有 —— 成本全给出去，
  收益一个没有。trait 的价值恰恰在这种「先修路后通车」的阶段最大。
- **只用 `#if canImport(AppKitPlus)`，不声明 trait。** tools-version 不用抬。否决：`canImport` 判断的是
  「模块能不能 import」，而依赖本身是无条件的 —— 结果与上一条完全相同，只是多了一层伪装，还让开关状态
  变得无法从 manifest 上看出来。
- **`@_exported import AppKitPlus`。** trait 开启时下游 `import RxAppKit` 即可直接用 AppKitPlus 全部
  API。否决：把上游的公开表面并入本库名下，本库的 API 表面会随上游每次发版漂移，而上游明确不保证
  API/ABI 稳定。UIFoundation 也否决了同一条。
- **真·空开关：加依赖但一行 `import` 也不写。** diff 最小。否决：trait 开与关在编译层面完全等价
  （Swift 的隐式传递可见性靠 import 链走），这次改动就验证不了任何东西 —— 尤其验证不了命名冲突面，
  而那正是唯一值得现在验证的东西。代价（两条破坏性变更）照付，收益归零。

## 影响

### 源码兼容性（source compatibility）

**有破坏，两处，都在包级 manifest，没有一处在 API 上。**

1. **包级 macOS 下限 10.13 → 12。** 部署目标低于 12 的消费者无法再依赖本库任何 product，与是否开启
   `AppKitPlus` trait 无关。平台下限没有软着陆机制，无法用 `@available(*, deprecated)` 提供过渡期。
2. **swift-tools-version 5.7 → 6.2。** 使用 Swift 6.2 以下工具链的消费者无法再解析本包。传导到本仓库
   自身：`Package.swift` 的语法可以用上 6.2 的全部特性，但语言模式由 `swiftLanguageModes: [.v5]` 钉在
   Swift 5，源码不受影响。

**公开 API 表面**：纯新增一个 `RxAppKitTraits` 枚举（一个静态常量），不破坏任何现有调用点。trait 开启
时下游**不会**自动获得 AppKitPlus 的 API（本提案不做 `@_exported`），但会继承一条命名约束 —— 见下。

**trait 开启时多出的一条下游约束**：`NSView` / `NSViewController` / `NSTableCellView` /
`NSCollectionViewItem` 等类的子类，不能声明与 AppKitPlus 挂在这些类上的 category 成员同名的属性
（Swift 判为非法 override，编译失败），且这条约束会经由 import 链传染给从不 `import AppKitPlus` 的
下游模块。trait 关闭时完全不存在。这是 trait 机制的既定含义 —— 开与关的 API 表面本就不同。

### ABI 兼容性

不适用 —— 本库以 SPM 源码分发，使用方每次重新编译。

（AppKitPlus 自身是 `binaryTarget` 二进制分发且开启了 library evolution，但那是它的 ABI，不是本库的。）

### 下游影响

- **本仓库内**：`Package.swift`、`Sources/RxAppKit/Common/AppKitPlus.swift`（新增）、
  `Tests/RxAppKitTests/AppKitPlusTraitTests.swift`（新增）、`CLAUDE.md`、`README.md`。
  `RxAppKitObjC` 与三个示例工程不受影响。
- **跨仓库**：本库有 11 个发布 tag（当前 0.5.4），是公开库，下游不完全可知。**部署目标在 10.13–11.x
  之间的消费者会被这次改动挡在门外** —— 这是本提案唯一真正的外部代价，且无法缓解。可查的本地消费者
  （`Examples/` 下三个示例工程）部署目标为 13.1 / 13.3，不受影响。

### 文档与示例

- **`CLAUDE.md`**：Project Overview 的平台行 `macOS 10.13+` → `macOS 12+`、Swift 行 `5.7+` → 工具链
  6.2+（语言模式 Swift 5）；Dependencies 行补 AppKitPlus（标注「可选，默认关闭」）；Build & Test 一节
  补 trait 开启的构建与测试命令；新增一节说明 `AppKitPlus` trait 的契约与升级复查约定。
- **`README.md`**（公开文档，英文）：新增 Requirements 一节，写明 macOS 12+ / Swift 6.2 toolchain；
  新增一小节说明 `AppKitPlus` trait 是什么、默认关闭、怎么开启。
- **`Documentations/README.md`** 与 **`Documentations/Evolutions/README.md`**：本提案同批次创建并登记。
- **示例代码**：无需改动（本次零使用代码）。

## API 演进与废弃策略

- 无 API 被替代，无需废弃标注。新增的 `RxAppKitTraits` 是纯增量。
- **需要一次 minor 跃迁**：平台下限与工具链下限抬升都是破坏性变更。本库当前最新 tag 为 0.5.4，本改动
  应落在 **0.6.0**（0.x 阶段的破坏性变更走 minor）。打 tag 的动作由用户执行。
- 上游 AppKitPlus 处于 pre-1.0 且自述无 API/ABI 稳定性保证，本库仍用 `from:` 而非 `.exact(_:)`：两个
  仓库同一作者，破坏性变更在本库这边同步处理。**代价是 0.5.0 会被自动取用**，因此每次升级都要重跑
  trait 开启的构建复查命名冲突面（前期调研第 4 条）。

## 落地步骤

已全部执行，实际结果记在下方验证矩阵。

1. **`Package.swift`**：抬 tools-version 到 6.2、抬 macOS floor 到 12、加 `traits:`、加依赖、加条件
   product 依赖、加 `swiftLanguageModes: [.v5]`。
   验证：`swift build --scratch-path /tmp/claude/SwiftPM/RxAppKit` 通过；`Package.resolved` 中**不**
   出现 `appkitplus-release`。
2. **新增 `Sources/RxAppKit/Common/AppKitPlus.swift`**（条件 import + `RxAppKitTraits`）。
   验证：`swift build --traits AppKitPlus --scratch-path …` 通过且 **0 error**，警告集合与第 1 步一致
   （即前期调研第 4 条那三条，一条不多）。
3. **新增 `Tests/RxAppKitTests/AppKitPlusTraitTests.swift`**。
   验证：trait 两侧各跑一次 `swift test`，结果应为 **41 tests / 7 issues**，失败集合与前期调研第 5 条
   记录的 4 个既有失败**完全相同**。退出码用 `${PIPESTATUS[0]}`（zsh 用 `${pipestatus[1]}`）取，不认
   xcsift 的摘要。
4. **文档同批次更新**：`CLAUDE.md`、`README.md`，以及本提案的落地编号与状态。
5. **提案编号与状态**：落地提交里把 `draft-appkitplus-trait.md` 重命名为 `0001-appkitplus-trait.md`，
   标题行与两份 README 的链接同步更新，状态改 `Implemented`。

### 验证矩阵

落地后实测（macOS 26 / Swift 6.3.3 / AppKitPlus-Release 0.4.2）：

| 命令 | 实测结果 |
|---|---|
| `swift build` | **通过**，0 error，3 条警告（2 条废弃 + 1 条 `??`），与前期调研第 6 条一致 |
| `swift build --traits AppKitPlus` | **通过**，0 error，警告集合与上一行**逐条相同** —— 命名冲突为零 |
| `swift test` | 41 tests / 6 suites / **7 issues**，失败集合 = 既有 4 个；新增测试通过 |
| `swift test --traits AppKitPlus` | 同上，新增测试通过 |
| `Package.resolved`（trait 关闭） | 不含 `appkitplus-release`，`git diff` 为空 |

测试的退出码取自 `swift test` 本身（退出码 1，因既有失败），未经 xcsift 中转。

**收尾时必须判断两件事**（结果写进决策日志）：要不要配套使用指南或实现说明；有没有引入需要登记的
新术语。

## 决策日志

| 日期 | 变更 | 说明 |
|------|------|------|
| 2026-09-20 | Created as Draft | 用户要求「像 UIFoundation 那样把 AppKitPlus 接进来」。完整档提案，两轮澄清提问后落笔 |
| 2026-09-20 | 范围定为「只搭骨架」 | 第一批不写任何使用代码。用户在第一轮选定 |
| 2026-09-20 | 否决独立包方案，直接抬 floor 到 12 | 用户在第一轮选定。跨包写 `.rx` 扩展会撞 `internal` 可见性，代价大于抬 floor |
| 2026-09-20 | 用 SPM trait 而非无条件依赖 | 用户在第一轮选定。连带 tools-version 必须升到 6.1+ |
| 2026-09-20 | 版本约束用 `from: "0.4.2"` | 用户在第一轮选定。配套约定：每次升级重跑 trait 开启构建复查冲突面 |
| 2026-09-20 | 加 canary 而非真·空开关 | 用户在第二轮选定。不 import 的话 trait 开与关在编译层面等价，命名冲突面根本测不出来 |
| 2026-09-20 | tools-version 选 6.2 而非 6.1 | 用户在第二轮选定，与 UIFoundation 口径一致 |
| 2026-09-20 | 文档建最小结构 | 用户在第二轮选定。只建 `Documentations/README.md` + `Evolutions/README.md` + 本文件 |
| 2026-09-20 | 落在 0.6.0 | 用户在第二轮选定 |
| 2026-09-20 | 2 条新增废弃警告不处理 | 用户在第三轮选定，记为已知副作用 |
| 2026-09-20 | canary 暴露公开 trait 状态常量 | 用户在第三轮选定，下游可查自己拿到的是哪个构建 |
| 2026-09-20 | Draft → Accepted | 用户批准，实现开始 |
| 2026-09-20 | Accepted → Implemented | 验证矩阵全部达标，提案编号分配为 0001 |
| 2026-09-20 | 收尾判断：不写配套文档 | 调用方契约（trait 怎么开、floor 为什么是 12、不 re-export）已写进 `CLAUDE.md` 与 `README.md`；canary 文件存在的理由写在文件自身的注释里。单独成篇只会重复 |
| 2026-09-20 | 收尾判断：不建术语表 | 本次唯一可能的新术语是 canary，属通用工程词汇；为一个词新建 `Glossary.md` 只会稀释它 |
