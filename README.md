# GodlingBattle

`GodlingBattle` 是一个全新的独立 Godot 项目，用来实现新的自动战斗系统。

这个项目与旧的 `Godling` 并列存在，目标是避免新旧战斗系统继续混在一起。旧项目只作为参考来源，不作为本项目的运行依赖。

## 当前目标

首期先做一个正式游戏风格的可玩 Demo，打通这条主流程：

`出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`

其中：

- 出战前准备：庄重神秘的战术陈列台风格
- 自动观战：2D 棋子 + 血条
- 结果结算：冷静的战术报告页

## 当前状态

当前仓库已完成：

- 项目方向确认
- 设计文档确认
- 实现计划确认
- 中文接力文档整理

当前尚未开始：

- 真正的 Godot 项目骨架创建
- 运行时代码实现
- 场景与 UI 落地

## 先看哪些文件

推荐阅读顺序：

1. [docs/HANDOFF.md](docs/HANDOFF.md)
2. [docs/项目概览.md](docs/%E9%A1%B9%E7%9B%AE%E6%A6%82%E8%A7%88.md)
3. [docs/实施计划导读.md](docs/%E5%AE%9E%E6%96%BD%E8%AE%A1%E5%88%92%E5%AF%BC%E8%AF%BB.md)
4. [docs/superpowers/specs/2026-03-30-godlingbattle-design.md](docs/superpowers/specs/2026-03-30-godlingbattle-design.md)
5. [docs/superpowers/plans/2026-03-30-godlingbattle.md](docs/superpowers/plans/2026-03-30-godlingbattle.md)

## 下一步

下一步从实现计划的 `Task 1` 开始，先把这个目录真正搭成一个可启动的 Godot 项目：

- 创建 `project.godot`
- 复制 `icon.svg`
- 创建主场景
- 创建基础 autoload

## 约定

- 新项目保持独立，不要把新系统文件再写回旧 `Godling`
- 首期不做混合交互战斗
- 统一使用术语 `出战前准备`，不要写成“远征前准备”
