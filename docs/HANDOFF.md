# GodlingBattle Handoff

## 当前状态

`GodlingBattle` 目前已经完成：

- 新项目目录与 Godot 项目骨架
- 第一阶段主流程与基础测试
- 第二阶段 runtime 加固（content/setup 驱动、事件分阶段、timeline 观战、结构化结果）
- 第三阶段观战可读性增强（token 渲染、阵营分层、HUD、低血量样式）
- 第四阶段 UI 产品化计划已落地并执行中

当前已经不在“文档阶段”，而是进入：

`phase4 UI 产品化执行中（准备页/观战页/结果页可见化）`

## 当前唯一依据

继续工作时，优先以这些文件为准：

1. [项目概览.md](./项目概览.md)
2. [实施计划导读.md](./实施计划导读.md)
3. [2026-03-30-godlingbattle-design.md](./superpowers/specs/2026-03-30-godlingbattle-design.md)
4. [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md)
5. [2026-03-30-godlingbattle-phase2-runtime.md](./superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md)
6. [2026-03-30-godlingbattle-phase4-ui-productization.md](./superpowers/plans/2026-03-30-godlingbattle-phase4-ui-productization.md)

## 项目目标一句话

做一个独立于旧 `Godling` 的新 Godot 项目，先打通这条正式游戏风格主流程：

`出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`

## 明天最建议先做什么（第四阶段）

直接从 `phase4` 计划的当前未完成 Task 开始：

- 保持准备页校验与内容注册表一致（不回退为硬编码）
- 完成观战地图层级与可读信息稳定性
- 完成结果页可见报告与返回链路 smoke 断言
- 更新交接状态并维持全链路回归通过

## 明天接着开工时可直接对 Codex 说的话

`请先阅读 docs/HANDOFF.md、docs/项目概览.md、docs/实施计划导读.md，然后按 docs/superpowers/plans/2026-03-30-godlingbattle-phase4-ui-productization.md 从当前未完成 Task 继续执行。`

## 提醒

- 新项目必须保持独立，不要再把新系统文件写回旧 `Godling`
- 首期不做混合交互战斗
- 出战前准备界面不要写成“远征前准备”，统一叫 `出战前准备`
