# RxAppKit

## Why create this
RxCocoa provides many convenient bindings and observables for iOS, but few for macOS.

The framework aims to provide rich extensions to RxSwift for macOS. The project is experimental and the API is subject to change.

## Claude Code Skill

This repo ships a [Claude Code](https://docs.claude.com/en/docs/claude-code) skill — `rxappkit-bindings` — that teaches the agent how to use RxAppKit idiomatically so it stops reaching for `PublishRelay` + `@objc` plumbing or hand-rolling `NSTableViewDataSource` / `NSOutlineViewDataSource` / `NSCollectionViewDataSource` / `NSBrowserDelegate` for data that already lives in an Rx stream.

It also surfaces the most easily missed feature: `Reactive` is `@dynamicMemberLookup`, and RxAppKit's `HasTargeAction` extension exposes **every** writable property on `NSControl` / `NSMenuItem` / `NSToolbarItem` / `NSGestureRecognizer` / `NSColorPanel` as a `ControlProperty` automatically.

### Install via Claude Code plugin marketplace (recommended)

In any Claude Code session run:

```text
/plugin marketplace add Mx-Iris/RxAppKit
/plugin install rxappkit-bindings@rxappkit
```

The first command registers this repo as a marketplace named `rxappkit` (defined by [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)); the second installs the `rxappkit-bindings` plugin and makes the skill globally available across all your projects. Updates: `/plugin marketplace update rxappkit`.

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
