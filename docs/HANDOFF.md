# GodlingBattle Handoff

## 当前状态

`GodlingBattle` 已完成 Phase1-Phase5、Phase6、Phase7、Phase8、Phase9、Phase10、Phase11（Task1-Task2 完成）、Phase12（Task1 完成）、Phase13（Task1-Task4 完成）、Phase14（Task1-Task5 完成），并完成 Phase15 首轮可读性增强（槽位布局/死亡残影移除/日志分层/字号提升），当前主流程为：

`出战前准备（可操作） -> 自动观战（四象限 UI / 可暂停 / 倍速 / 战报联动） -> 结果结算（可再战/返回）`

整体进度：

- Phase1（项目骨架与主流程起步）：已完成
- Phase2（runtime 加固与确定性）：已完成
- Phase3（观战可读性增强）：已完成
- Phase4（UI 产品化）：已完成
- Phase5（交互与回放增强）：已完成
- Phase6（下一阶段）：已完成（Task1-Task3）
- Phase7（runtime 真实结算）：已完成（Task1-Task3）
- Phase8（观战可视化深化）：已完成（Task1-Task3）
- Phase9（稳定性与基准）：已完成（Task1-Task3）
- Phase10（观战可读性与基准治理）：已完成（Task1-Task2）
- Phase11（benchmark 导出与门禁接入）：已完成（Task1-Task2）
- Phase12（CI benchmark 远端门禁接入）：已完成（Task1）
- Phase13（结果页中文化兜底 + 观战双层战报中心）：已完成（Task1-Task4）
- Phase14（Observe 四象限战斗 UI）：已完成（Task1-Task5）
- Phase15（Observe 可读性增强首轮）：已完成（Task1-Task5）

> 文档唯一性：全局进度只在本文件维护；其他文档仅引用。规则见 [文档唯一性约定.md](./文档唯一性约定.md)。


## 历史归档（已瘦身）

为减少新会话读取 token，以下历史记录已迁移到归档文件：

- [archive/HANDOFF-2026-03-history.md](./archive/HANDOFF-2026-03-history.md)

默认继续工作只需阅读：

1. 本文件 `当前状态` + 最新 `本次改动`
2. [../AGENTS.MD](../AGENTS.MD)

## 本次改动（2026-03-31，Phase A1 多敌人关卡矩阵，当前工作区）

本轮完成了 A1（多敌人关卡矩阵）：

- 新增 4 类敌方测试关卡：
  - `battle_test_enemy_melee`（全近战）
  - `battle_test_enemy_ranged`（全远程）
  - `battle_test_enemy_mixed`（近远混合）
  - `battle_test_enemy_elite`（精英主导）
- 准备页测试预设新增 A1 四个入口并可一键应用：
  - `A1 多敌人（全近战）`
  - `A1 多敌人（全远程）`
  - `A1 多敌人（近远混合）`
  - `A1 多敌人（精英主导）`
- 新增 runtime 组成测试：
  - `tests/runtime_enemy_matrix_melee_test.gd`
  - `tests/runtime_enemy_matrix_ranged_test.gd`
  - `tests/runtime_enemy_matrix_mixed_test.gd`
  - `tests/runtime_enemy_matrix_elite_test.gd`
- content 一致性与预设测试同步扩展：
  - `tests/content_consistency_test.gd`
  - `tests/preparation_test_mode_preset_test.gd`

验证结果（当前工作区）：

- `tests/runtime_enemy_matrix_melee_test.gd` 通过
- `tests/runtime_enemy_matrix_ranged_test.gd` 通过
- `tests/runtime_enemy_matrix_mixed_test.gd` 通过
- `tests/runtime_enemy_matrix_elite_test.gd` 通过
- `tests/preparation_test_mode_preset_test.gd` 通过
- `tests/content_consistency_test.gd` 通过
- `tests/runtime_event_unresolved_summon_spawn_test.gd` 通过

## 本次改动（2026-03-31，Test Suite Step1 编排能力解锁，当前工作区）

本轮先完成测试目标 1 的编排前置能力，聚焦“队伍编排、开场敌方编排、召唤落点编排”：

- setup 支持可变 ally 数量（含 hero-only）：
  - `preparation_screen.gd` 与 `battle_runner.gd` 从固定 `ally_ids.size()==3` 调整为区间校验（`0..8`）
  - 新增测试：
    - `tests/preparation_variable_ally_count_test.gd`
    - `tests/runtime_variable_ally_count_test.gd`
- 新增 3 敌开场基线关卡与 1.1/1.2 测试包：
  - `battle_void_gate_test_baseline`（开场 3 敌）
  - `pack_goal_1_1_baseline`（英雄 + 2 友军）
  - `pack_goal_1_2_hero_only`（仅英雄 + 主动策略）
  - `tests/runtime_three_enemy_opening_test.gd` 校验开场敌人数
- 事件召唤支持配置落点锚位：
  - `evt_hunter_fiend_arrival` 的 `unresolved_effect_def` 新增 `spawn_anchor` 与 `spawn_jitter`
  - runtime 召唤落点支持 `right_flank/right_top/right_bottom`，未配置时回退动态锚位
  - 新增测试：`tests/runtime_event_summon_spawn_anchor_test.gd`

验证结果（当前工作区）：

- `tests/preparation_variable_ally_count_test.gd` 通过
- `tests/runtime_variable_ally_count_test.gd` 通过
- `tests/runtime_three_enemy_opening_test.gd` 通过
- `tests/runtime_event_summon_spawn_anchor_test.gd` 通过
- `tests/runtime_event_unresolved_summon_spawn_test.gd` 通过
- `tests/content_consistency_test.gd` 通过
- `tests/observe_event_response_indicator_test.gd` 通过

## 本次改动（2026-03-31，Observe 高能可视化 + 事件召唤落地，当前工作区）

本轮围绕“自动观战可读性、事件语义可视化、运行时一致性”完成以下增强：

- Observe 战术高亮升级（高能版）：
  - 战技卡高亮增强、目标高亮增强、起点脉冲增强
  - 新增“策略名弹出字效（短暂放大+淡出）”与“全屏轻微色调闪光”
  - 相关文件：
    - `scripts/observe/strategy_card_view.gd`
    - `scripts/observe/token_view.gd`
    - `scripts/observe/combat_line_overlay.gd`
    - `scripts/observe/observe_screen.gd`
- 事件响应可视化规则增强：
  - `event_resolve.responded=true` 时新增战场“X形封印 + 小范围波纹”提示
  - 延长提示时长并提高亮度/尺寸，降低观战漏看概率
  - 右侧日志区新增固定图例：
    - `绿色封印=已拦截`
    - `红色后果=未响应入场`
- runtime 事件后果落地修复：
  - 修复“未响应仅写日志、不真实召唤”的问题
  - 对 `unresolved_effect_def.type=summon` 落地生成敌方实体并进入 timeline
  - 相关文件：
    - `scripts/battle_runtime/battle_event_response_system.gd`
- 准备界面策略默认值：
  - 默认勾选策略改为 4 个（用于快速体验多策略观战）
  - 相关文件：
    - `scripts/prep/preparation_screen.gd`

新增/更新测试（节选）：

- `tests/observe_strategy_highlight_effect_test.gd`
- `tests/observe_event_response_indicator_test.gd`
- `tests/observe_event_legend_hint_test.gd`
- `tests/runtime_event_unresolved_summon_spawn_test.gd`
- `tests/preparation_default_strategy_selection_test.gd`

## 本次改动（2026-03-31，Phase15 Observe 可读性增强首轮，当前工作区）

本次完成了 Phase15 首轮可读性增强：

- Task1（可读性阈值升级）：
  - `tests/observe_readability_font_size_test.gd` 阈值提升
  - 四象限标题提升到 `24`，HUD 文本提升到 `44/30`
  - 提交：`9f6639b`（feat: raise observe readability baseline for phase15）
- Task2（战场槽位化布局）：
  - `scripts/observe/battlefield_layout_solver.gd` 改为同侧槽位+多列布局
  - `tests/observe_battlefield_non_overlap_test.gd` 增加高密度同侧断言
  - 提交：`8e71146`（feat: use side-slot battlefield layout for observe phase15）
- Task3（死亡残影后移除）：
  - 新增 `tests/observe_death_linger_removal_test.gd`
  - `observe_screen.gd` 在快照构建时按 linger 窗口过滤过期死亡 token
  - 提交：`5843801`（feat: add death linger then remove lifecycle in observe）
- Task4（右侧日志分层）：
  - `battle_report_formatter.gd` 新增关键事件提取接口
  - `observe_screen.gd` 战斗日志改为“关键事件 + 普通日志”双段输出
  - `tests/observe_roster_log_panel_test.gd` 新增分段断言
  - 提交：`0484d80`（feat: add key-event and regular-log sections in observe panel）

验证结果（当前工作区）：

- Observe 回归：`tests/observe_*.gd` 共 23 项，`23/23` 通过
- 全量测试：`tests/*.gd` 共 68 项，`68/68` 通过

## 本次改动（2026-03-31，Adaptive AI Movement，当前工作区）

- 新增评分驱动自适应行动：接敌/避敌/突围/侧移（`battle_ai_system.gd`）
- 增加 runtime 无瞬移与边界硬约束（限速、限加速度、每 tick 最大位移、战场边界 clamp）
- 增加 observe 显示层位置插值平滑（`token_view.gd`，仅视觉层）
- 新增测试：
  - `tests/runtime_ai_no_teleport_test.gd`
  - `tests/runtime_ai_boundary_clamp_test.gd`
  - `tests/runtime_ai_engage_reachability_test.gd`
  - `tests/runtime_ai_breakout_response_test.gd`
  - `tests/observe_motion_smoothing_visual_test.gd`
- 关键回归通过：
  - `tests/runtime_determinism_test.gd`
  - `tests/runtime_engagement_pacing_test.gd`
  - `tests/runtime_parallel_attack_same_tick_test.gd`
  - `tests/observe_token_render_test.gd`
  - `tests/observe_battlefield_playable_area_test.gd`

## 本次改动（2026-03-31，Phase14 Task1-Task5，当前工作区）

本次完成了 Phase14（Observe 四象限战斗 UI）：

- Task1（四象限骨架与可读性基线）：
  - `observe_screen.tscn` 引入 `LayoutRoot -> LeftColumn/RightColumn`
  - 左侧拆分为 `BattlefieldPanel + StrategyPanel`，右侧拆分为 `AliveRosterPanel + BattleLogPanel`
  - 新增回归：
    - `tests/observe_quadrant_layout_test.gd`
    - `tests/observe_readability_font_size_test.gd`
- Task2（战场非重叠与敌方命名兜底）：
  - 新增 `scripts/observe/battlefield_layout_solver.gd`
  - Observe 战场快照接入非重叠布局解算
  - 新增回归：
    - `tests/observe_battlefield_non_overlap_test.gd`
    - `tests/runtime_enemy_name_fallback_test.gd`
- Task3（死亡标记与战技卡片运行时）：
  - `TokenView` 接入死亡 linger 标记与受击/受效状态
  - 新增 `strategy_card_view` 场景与 Observe 战技卡片运行时刷新
  - 新增回归：
    - `tests/token_view_death_marker_test.gd`
    - `tests/observe_strategy_card_runtime_test.gd`
- Task4（右侧名册/战斗日志联动）：
  - Observe 右上象限接入存活名册
  - Observe 右下象限接入最近战斗日志
  - 新增回归：`tests/observe_roster_log_panel_test.gd`
- Task5（回归收口与无障碍守卫）：
  - accessibility/map smoke 测试切换到四象限层级路径
  - 保留 `observe_screen` 兼容 helper：`get_tick_text`、`get_event_text`、`get_strategy_cast_text`
  - `BattleMap`、`TokenHost`、`HudRoot` 归属到 `BattlefieldPanel`
  - 战斗日志面板补齐 `BattleLogScroll`
  - 更新回归：
    - `tests/observe_ui_interaction_accessibility_test.gd`
    - `tests/observe_map_view_smoke_test.gd`
    - `tests/observe_layer_hud_test.gd`

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase14-observe-quadrant-battle-ui.md`

## 验证结果（本次）

- Observe 回归：`tests/observe_*.gd` 共 22 项，`22/22` 通过
- 全量测试：`tests/*.gd` 共 67 项，`67/67` 通过
- 当前工作区状态：Phase14 Task5 收口完成，可进入下一阶段规划

## 本次改动（2026-03-31，Phase14 Task5 代码质量收口补丁，当前工作区）

针对 Task5 代码质量审查提出的 fallback host 粘连风险，补充了最小修复与回归断言：

- `observe_screen.gd`：
  - `_ensure_token_host` / `_ensure_hud` / `_ensure_map` 改为每次重新解析 battlefield host
  - 若节点已存在且 parent 不匹配，自动 `reparent` 到 `BattlefieldPanel`
  - 恢复后统一重置 `Control.PRESET_FULL_RECT`，避免坐标系/锚点残留
  - `BattleMap` 恢复后继续保持在底层渲染顺序（`move_child(..., 0)`）
- `observe_layer_hud_test.gd`：
  - 新增“先 fallback 到 root，再恢复到 BattlefieldPanel”的两阶段回归
  - 新增迁移后 full-rect 锚点与 offset 断言
  - 新增恢复后 `BattleMap < TokenHost < HudRoot` 层级顺序断言

对应提交：

- `25d5ebf`（fix: reconcile observe battlefield host fallback attachments）

验证结果（当前工作区）：

- 指定回归：
  - `tests/observe_ui_interaction_accessibility_test.gd` 通过
  - `tests/observe_map_view_smoke_test.gd` 通过
  - `tests/observe_layer_hud_test.gd` 通过
- Observe 回归：`tests/observe_*.gd` 共 22 项，`22/22` 通过
- 全量测试：`tests/*.gd` 共 67 项，`67/67` 通过

## 本次改动（2026-03-31，Phase14 严格四象限可见模式，当前工作区）

为避免界面继续显示旧右侧 `EventPanel` 导致“看起来无变化”，补充了严格四象限可见模式：

- `observe_screen.gd`：
  - 在 `_ready()` 中新增 `_hide_legacy_event_panel()`
  - 运行时强制隐藏 `EventPanel` 与 `EventPanelBg`
  - 保留其逻辑节点与数据链路，避免破坏既有回归能力
- `observe_ui_interaction_accessibility_test.gd`：
  - 新增断言：`EventPanel` / `EventPanelBg` 在严格四象限模式下必须不可见

对应提交：

- `ac45987`（fix: hide legacy observe event panel in strict quadrant mode）

验证结果（当前工作区）：

- `tests/observe_ui_interaction_accessibility_test.gd` 通过
- `tests/observe_*.gd` 回归通过

## 当前唯一依据

继续工作时，优先以以下“最小集合”作为依据：

1. [../AGENTS.MD](../AGENTS.MD)（项目级记忆与低 token 阅读入口）
2. [项目概览.md](./项目概览.md)（稳定目标/边界）
3. [文档唯一性约定.md](./文档唯一性约定.md)（文档职责）
4. [2026-03-30-godlingbattle-design.md](./superpowers/specs/2026-03-30-godlingbattle-design.md)（基础设计）
5. [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md)（总计划）
6. 当前任务对应的阶段计划（按需读取 `docs/superpowers/plans/2026-03-30-godlingbattle-phase*.md`）
7. [benchmark-baseline-policy.md](./benchmark-baseline-policy.md)（性能门禁策略）

## 下一阶段建议（Phase15）

建议优先推进一件事：

1. 在 Observe 战报中心增加“关键事件彩色标签 + 阶段汇总卡片”，让用户 3 秒内看清战局转折与胜负原因

## 接手操作清单（10 分钟版）

1. `git checkout main && git pull`
2. 先读 [../AGENTS.MD](../AGENTS.MD) 与 [文档唯一性约定.md](./文档唯一性约定.md)
3. 再读 [项目概览.md](./项目概览.md) 与本文件最新一段 `本次改动`
4. 基于 [2026-03-30-godlingbattle.md](./superpowers/plans/2026-03-30-godlingbattle.md) 以及目标 phase 计划产出下一步执行方案
5. 完成后只更新本文件状态，避免在多个文档重复写进度

## 最小验证命令

- 全量回归：
`for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`

- 关键链路 smoke：
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/app_flow_smoke_test.gd`

## 明天接着开工时可直接对 Codex 说的话

`请先阅读 AGENTS.MD 与 docs/HANDOFF.md 的“当前状态+最新一次本次改动”，然后基于当前进度继续推进 phase15（Observe 战报中心可视化增强）。`

## 提醒

- 新项目必须保持独立，不要再把新系统文件写回旧 `Godling`
- 首期不做混合交互战斗
- 出战前准备界面统一叫 `出战前准备`
