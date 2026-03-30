# GodlingBattle Handoff

## 当前状态

`GodlingBattle` 已完成 Phase1-Phase5，当前主流程为：

`出战前准备（可操作） -> 自动观战（可暂停/倍速） -> 结果结算（可再战/返回）`

整体进度：

- Phase1（项目骨架与主流程起步）：已完成
- Phase2（runtime 加固与确定性）：已完成
- Phase3（观战可读性增强）：已完成
- Phase4（UI 产品化）：已完成
- Phase5（交互与回放增强）：已完成
- Phase6（下一阶段）：未开始

> 文档唯一性：全局进度只在本文件维护；其他文档仅引用。规则见 [文档唯一性约定.md](./文档唯一性约定.md)。

## 本次改动（2026-03-30，已合并到 main）

本次完成了 Phase5 全部任务：

- 准备页新增交互控件：英雄/关卡/种子/战技开关
- 新增预算反馈：超预算显示并禁用开始按钮
- 观战页新增播放控制：暂停/继续 + 倍速（1x/2x/4x）
- 结果页新增 `再战一场` 并重进 Observe
- app flow smoke 扩展到 replay 分支
- Phase5 计划文档与交接文档同步更新

对应提交：

- 功能基线：`a8d75ae`（Phase5 功能完成）
- 文档治理基线：`73b11b0`（文档唯一性与职责收敛）

当前建议以 `73b11b0` 作为接力起点（`main` 最新）。

## 验证结果（本次）

- 全量测试：`tests/*.gd` 共 30 项，`30/30` 通过
- 主仓状态：`main` 与 `origin/main` 对齐，工作区干净

## 当前唯一依据

继续工作时，优先以这些文件为准：

1. [项目概览.md](./项目概览.md)
2. [实施计划导读.md](./实施计划导读.md)
3. [文档唯一性约定.md](./文档唯一性约定.md)
4. [2026-03-30-godlingbattle-design.md](./superpowers/specs/2026-03-30-godlingbattle-design.md)
5. [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md)
6. [2026-03-30-godlingbattle-phase2-runtime.md](./superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md)
7. [2026-03-30-godlingbattle-phase4-ui-productization.md](./superpowers/plans/2026-03-30-godlingbattle-phase4-ui-productization.md)
8. [2026-03-30-godlingbattle-phase5-interaction-replay.md](./superpowers/plans/2026-03-30-godlingbattle-phase5-interaction-replay.md)

## 下一阶段建议（Phase6）

建议优先推进三件事：

1. 准备页从“单战技开关”升级为可扩展多战技选择组件
2. 观战增加进度条/跳帧能力，形成完整 replay 操作闭环
3. 增加长时间线与复杂事件组合下的稳定性回归测试

## 接手操作清单（10 分钟版）

1. `git checkout main && git pull`
2. 先读 [文档唯一性约定.md](./文档唯一性约定.md)（明确哪些文档可以更新状态）
3. 再读 [项目概览.md](./项目概览.md) 与 [实施计划导读.md](./实施计划导读.md)
4. 基于 [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md) 产出 phase6 计划
5. 从 phase6 Task 1 开始执行，并在完成后只更新本文件状态

## 最小验证命令

- 全量回归：
`for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`

- 关键链路 smoke：
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/app_flow_smoke_test.gd`

## 明天接着开工时可直接对 Codex 说的话

`请先阅读 docs/HANDOFF.md、docs/项目概览.md、docs/实施计划导读.md，然后基于当前进度产出 phase6 实施计划并从 Task 1 开始执行。`

## 提醒

- 新项目必须保持独立，不要再把新系统文件写回旧 `Godling`
- 首期不做混合交互战斗
- 出战前准备界面统一叫 `出战前准备`
