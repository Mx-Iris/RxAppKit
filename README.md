# RxAppKit

## Why create this
RxCocoa provides many convenient bindings and observables for iOS, but few for macOS.

The framework aims to provide rich extensions to RxSwift for macOS. The project is experimental and the API is subject to change.

## Requirements

- macOS 12+
- Swift 6.2 toolchain (the package itself builds in Swift 5 language mode)

## Optional: the `AppKitPlus` trait

RxAppKit declares one SPM trait, `AppKitPlus`, and it is **off by default**. Turning it on links
[AppKitPlus](https://github.com/AppKitSupportProgram/AppKitPlus-Release), a binary framework that ports
modern UIKit API shapes — content configurations, diffable data sources, cell registration, trait
collections, block animation — onto AppKit.

```swift
.package(url: "https://github.com/Mx-Iris/RxAppKit", from: "0.6.0", traits: ["AppKitPlus"])
```

No RxAppKit API depends on it yet: the trait is the conduit for `.rx` bindings still to come, and today
only exposes `RxAppKitTraits.isAppKitPlusEnabled` so a call site can tell which build it got. AppKitPlus
is not re-exported — to call its API, depend on it directly.

With the trait off, SwiftPM neither clones the repository nor downloads the framework. The macOS 12
requirement applies either way: that floor is AppKitPlus's, and SwiftPM enforces it on the package graph
rather than at compile time.

## Agent Skill (Claude Code and Codex)

This repo ships an agent skill — `rxappkit-bindings`, installable as a plugin in [Claude Code](https://docs.claude.com/en/docs/claude-code) and Codex — that teaches the agent how to use RxAppKit idiomatically so it stops reaching for `PublishRelay` + `@objc` plumbing or hand-rolling `NSTableViewDataSource` / `NSOutlineViewDataSource` / `NSCollectionViewDataSource` / `NSBrowserDelegate` for data that already lives in an Rx stream.

It also surfaces the most easily missed feature: `Reactive` is `@dynamicMemberLookup`, and RxAppKit's `HasTargeAction` extension exposes **every** writable property on `NSControl` / `NSMenuItem` / `NSToolbarItem` / `NSGestureRecognizer` / `NSColorPanel` as a `ControlProperty` automatically.

### Install via Claude Code plugin marketplace (recommended)

In any Claude Code session run:

```text
/plugin marketplace add Mx-Iris/RxAppKit
/plugin install rxappkit-bindings@rxappkit
```

The first command registers this repo as a marketplace named `rxappkit` (defined by [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)); the second installs the `rxappkit-bindings` plugin and makes the skill globally available across all your projects. An installed plugin picks up a new version of the skill when the plugin's `version` changes: `claude plugin marketplace update rxappkit`, then `claude plugin update rxappkit-bindings@rxappkit`.

To auto-register the marketplace for a whole team, drop this into a project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "rxappkit": {
      "source": { "source": "github", "repo": "Mx-Iris/RxAppKit" }
    }
  }
}
```

### Install in Codex

```bash
codex plugin marketplace add Mx-Iris/RxAppKit
codex plugin add rxappkit-bindings@rxappkit
```

Codex reads the marketplace from [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json), which points at the same plugin directory. Updates: `codex plugin marketplace upgrade rxappkit`.

### Project-local (automatic when working inside this repo)

When you clone this repo and use Claude Code inside it, the skill at `.claude/skills/rxappkit-bindings/SKILL.md` (a symlink into the plugin tree) is auto-discovered — no install step required.

### Manual install (if you don't use the marketplace)

```bash
# Option A — symlink so `git pull` keeps it up to date
mkdir -p ~/.claude/skills
ln -s "$(pwd)/plugins/rxappkit-bindings/skills/rxappkit-bindings" ~/.claude/skills/rxappkit-bindings

# Option B — copy a snapshot
mkdir -p ~/.claude/skills/rxappkit-bindings
cp plugins/rxappkit-bindings/skills/rxappkit-bindings/SKILL.md ~/.claude/skills/rxappkit-bindings/SKILL.md

# Option C — fetch from GitHub without cloning
mkdir -p ~/.claude/skills/rxappkit-bindings
curl -fsSL https://raw.githubusercontent.com/Mx-Iris/RxAppKit/main/plugins/rxappkit-bindings/skills/rxappkit-bindings/SKILL.md \
  -o ~/.claude/skills/rxappkit-bindings/SKILL.md
```

Verify any of the above by starting a Claude Code session — `rxappkit-bindings` should appear in the available-skills list whenever a relevant task triggers it.

## Thanks
The objc swizzle code comes from [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)
