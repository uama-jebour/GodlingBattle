# GodlingBattle Handoff

## 当前状态

`GodlingBattle` 目前已经完成：

- 新项目目录与 Godot 项目骨架
- 第一阶段主流程与基础测试
- 第二阶段 runtime 加固（content/setup 驱动、事件分阶段、timeline 观战、结构化结果）
- 第三阶段观战可读性增强（token 渲染、阵营分层、HUD、低血量样式）
- 第四阶段 UI 产品化（准备/观战/结果页面可见化）
- 第五阶段交互与回放增强（准备页交互控件、预算约束反馈、观战暂停/倍速、结果页再战）

当前基线：

`phase5 交互与回放链路已打通（准备 -> 观战 -> 结果 -> 再战/返回）`

## 当前唯一依据

继续工作时，优先以这些文件为准：

1. [项目概览.md](./项目概览.md)
2. [实施计划导读.md](./实施计划导读.md)
3. [2026-03-30-godlingbattle-design.md](./superpowers/specs/2026-03-30-godlingbattle-design.md)
4. [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md)
5. [2026-03-30-godlingbattle-phase2-runtime.md](./superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md)
6. [2026-03-30-godlingbattle-phase4-ui-productization.md](./superpowers/plans/2026-03-30-godlingbattle-phase4-ui-productization.md)
7. [2026-03-30-godlingbattle-phase5-interaction-replay.md](./superpowers/plans/2026-03-30-godlingbattle-phase5-interaction-replay.md)

## 项目目标一句话

做一个独立于旧 `Godling` 的新 Godot 项目，持续打磨这条正式游戏风格主流程：

`出战前准备（可操作） -> 自动观战（可暂停/倍速） -> 结果结算（可再战/返回）`

## 明天最建议先做什么（下一阶段）

建议从下一阶段（phase6）开始，优先做三件事：

- 将准备页从“单项战技开关”升级为可扩展多战技选择组件
- 增加观战进度条/拖拽跳帧能力，形成完整 replay 交互
- 补齐 replay 分支在更长 timeline/更复杂事件下的稳定性回归

## 明天接着开工时可直接对 Codex 说的话

`请先阅读 docs/HANDOFF.md、docs/项目概览.md、docs/实施计划导读.md，然后按 docs/superpowers/plans/2026-03-30-godlingbattle-phase5-interaction-replay.md 的未完成项继续执行。`

## 提醒

- 新项目必须保持独立，不要再把新系统文件写回旧 `Godling`
- 首期不做混合交互战斗
- 出战前准备界面统一叫 `出战前准备`
