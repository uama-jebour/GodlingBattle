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

当前仓库已完成第一阶段主流程打通：

- 已创建并可启动 `GodlingBattle` Godot 项目
- 已落地基础数据层与测试包导出工具
- 已打通 `出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`
- 已补齐 headless 基础测试（内容、准备、runtime、观战、结果、导出）

## 先看哪些文件

推荐阅读顺序：

1. [docs/HANDOFF.md](docs/HANDOFF.md)
2. [docs/项目概览.md](docs/%E9%A1%B9%E7%9B%AE%E6%A6%82%E8%A7%88.md)
3. [docs/实施计划导读.md](docs/%E5%AE%9E%E6%96%BD%E8%AE%A1%E5%88%92%E5%AF%BC%E8%AF%BB.md)
4. [docs/superpowers/specs/2026-03-30-godlingbattle-design.md](docs/superpowers/specs/2026-03-30-godlingbattle-design.md)
5. [docs/superpowers/plans/2026-03-30-godlingbattle.md](docs/superpowers/plans/2026-03-30-godlingbattle.md)
6. [docs/superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md](docs/superpowers/plans/2026-03-30-godlingbattle-phase2-runtime.md)

## 下一步

下一步建议进入第二阶段：在保持现有主流程稳定的前提下，补齐 runtime 与观战/结算层的“产品级最小闭环”：

- 让 runtime 真正从 `battle_setup + content` 驱动实体与结算
- 补齐事件 warning/response/生效的最小规则闭环
- 让观战层消费 timeline，而不是仅计算后直接跳转
- 让结果页展示结构化战报字段（survivors/casualties/events/strategies）

## 约定

- 新项目保持独立，不要把新系统文件再写回旧 `Godling`
- 首期不做混合交互战斗
- 统一使用术语 `出战前准备`，不要写成“远征前准备”
- Godot 元数据文件 `*.uid` 与资源导入配置 `*.import` 需纳入版本管理
- 继续忽略 `.godot/` 与 `.import/` 目录缓存，不提交引擎缓存产物
