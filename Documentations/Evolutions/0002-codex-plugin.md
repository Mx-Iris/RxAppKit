# 0002 - `rxappkit-bindings` 插件同时支持 Codex，skill 只在本仓库维护

- **状态**: Implemented
- **创建日期**: 2026-09-27
- **最后更新**: 2026-09-27

## 摘要

`rxappkit-bindings` skill 原本有两份：本仓库插件里一份（只给 Claude Code 装），维护者本机的全局
agent 配置里还有一份，同时给 Claude Code 和 Codex 用，两份各自演进。本次把本机那份的改动并回
本仓库、删掉本机副本，并给插件补上 Codex 的清单，让 Codex 也能直接从 GitHub 安装。从此这个
skill 只在本仓库维护。

## 方案

- **并回的改动**：两份正文逐字相同，唯一差别是 `description`——本机那份在一次全局 skill 瘦身里
  压短过（保留全部触发词，去掉冗余的场景铺陈）。采用压短后的版本。
- **Codex 支持**：新增 `plugins/rxappkit-bindings/.codex-plugin/plugin.json` 与
  `.agents/plugins/marketplace.json`（Codex 在仓库根找 marketplace 的固定位置），指向与 Claude Code
  相同的插件目录，skill 仍只有一份。Codex 的 marketplace 里 `./plugins/…` 以 `.agents/` 所在目录
  （即仓库根）为基准解析。
- **版本号**：Codex 清单要求版本号，于是两份清单都写 `1.0.0`，Claude Code 那份顺带补上了官方
  校验器提示缺少的 `version` 与 `author`。这改变了 Claude Code 侧的更新方式：此前没有版本号时，
  已安装的插件按提交哈希缓存；现在两个工具都只在版本号变化时更新，因此「改 skill 必升版本号、
  两份一致」写进了 `CLAUDE.md`。
- **校验**：`claude plugin validate`（插件与 `--strict` 的 marketplace）、Codex 的
  `validate_plugin.py` 与 `quick_validate.py` 均通过；在一个临时 `CODEX_HOME` 里实际执行了
  「添加 marketplace → 安装」，skill 落进了插件缓存。
- **README**：原「Claude Code Skill」一节改为同时覆盖两个工具，新增 Codex 的安装与更新命令。

## 决策日志

| 日期 | 决定 | 理由 |
|------|------|------|
| 2026-09-27 | skill 只在本仓库维护，删掉维护者本机的副本 | 维护者提出：已经装了本仓库的插件，本机不再另维护一份 |
| 2026-09-27 | 给插件加 Codex 清单 | 本机副本原本也供 Codex 使用，删掉后 Codex 需要另一个来源；维护者选择加清单而不是放弃 Codex |
| 2026-09-27 | 两份清单都用版本号 `1.0.0`，改 skill 时一起升 | Codex 必须有版本号；两边用同一条更新规则，比 Claude Code 按提交、Codex 按版本号更不容易出错 |
