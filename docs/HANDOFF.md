# GodlingBattle Handoff

## 当前状态

`GodlingBattle` 目前已经完成：

- 新项目目录与 Godot 项目骨架
- 核心设计文档与第一阶段实施计划
- 第一阶段代码落地（数据层、准备页、runtime、观战页、结果页、导出工具）
- headless 基础测试集

当前已经不在“文档阶段”，而是进入：

`第一阶段主流程已打通，准备进入第二阶段增强`

## 当前唯一依据

继续工作时，优先以这些文件为准：

1. [项目概览.md](./项目概览.md)
2. [实施计划导读.md](./实施计划导读.md)
3. [2026-03-30-godlingbattle-design.md](./superpowers/specs/2026-03-30-godlingbattle-design.md)
4. [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md)
5. [2026-03-30-godlingbattle-phase2-runtime.md](./superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md)

## 项目目标一句话

做一个独立于旧 `Godling` 的新 Godot 项目，先打通这条正式游戏风格主流程：

`出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`

## 明天最建议先做什么（第二阶段）

直接从 `phase2` 计划的 `Task 1` 开始：

- 补齐内容注册表与测试包 ID 一致性
- 让 runtime 真实消费 `battle_setup + content`
- 打通事件 warning/response/生效最小闭环
- 让观战层消费 timeline，并补结果页结构化摘要字段

## 明天接着开工时可直接对 Codex 说的话

`请先阅读 docs/HANDOFF.md、docs/项目概览.md、docs/实施计划导读.md，然后按 docs/superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md 从 Task 1 开始执行。`

## 提醒

- 新项目必须保持独立，不要再把新系统文件写回旧 `Godling`
- 首期不做混合交互战斗
- 出战前准备界面不要写成“远征前准备”，统一叫 `出战前准备`
