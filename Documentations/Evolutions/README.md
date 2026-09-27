# 演进提案

- **项目类型**: library

RxAppKit 的每一次实质性改动都留下一份提案，覆盖从调研到落地的完整生命周期。**一次改动 = 一份文件**：
不拆成 design / plan / report 多份，随工作进展在原地更新。

被否决的提案**保留不删** —— 它是「当初为什么没这么做」的唯一记录。

## 编号

提案在**落到共享分支的那一次提交里**才分配编号。在途提案的文件名是 `draft-<slug>.md`，标题行写
`# Draft - 标题`；落地时重命名为 `NNNN-<slug>.md` 并同步标题行与所有同仓库链接。

## 状态

| 状态 | 含义 |
|------|------|
| Draft | 正在撰写，尚未就绪 |
| In Review | 开放讨论中 |
| Accepted | 已批准，可以开始实现 |
| In Progress | 实现进行中 |
| Implemented | 实现完成并已合入 |
| Rejected | 已否决（保留存档，含否决理由） |
| Deferred | 方案成立但推迟 |
| Withdrawn | 作者撤回 |

## 提案列表

| # | 标题 | 状态 |
|---|------|------|
| 0001 | [AppKitPlus：以默认关闭的 SPM trait 接入可选依赖](0001-appkitplus-trait.md) | Implemented |
| 0002 | [`rxappkit-bindings` 插件同时支持 Codex，skill 只在本仓库维护](0002-codex-plugin.md) | Implemented |
