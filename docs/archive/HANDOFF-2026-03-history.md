# GodlingBattle Handoff History Archive (2026-03)

## 说明

本文件归档 `docs/HANDOFF.md` 的历史执行记录（已从主 handoff 瘦身迁出），用于需要追溯详细演进时按需查阅。

归档范围：

- 2026-03-30 已合并基线（Phase5）
- Phase6 Task1-Task3
- Phase7 Task1-Task3
- Phase8 Task1-Task3
- Phase9 Task1-Task3
- Phase10 Task1-Task2
- Phase11 Task1-Task2
- Phase12 Task1
- Phase13 Task1-Task4

---
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

## 本次改动（2026-03-30，Phase6 Task1，当前工作区）

本次完成了 Phase6 Task1（准备页多战技选择组件）：

- 准备页由单战技开关升级为动态多战技复选列表
- 战技选项改为从内容层动态读取并渲染（支持后续扩展）
- 保持 `battle_setup.strategy_ids` 输出契约不变
- 预算联动与禁用开始按钮逻辑保持生效
- 新增多战技选择测试并通过全量回归

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase6-preparation-multi-strategy.md`

验证结果（当前工作区）：

- 关键链路 smoke：`tests/app_flow_smoke_test.gd` 通过
- 全量测试：`tests/*.gd` 共 31 项，`31/31` 通过

## 本次改动（2026-03-30，Phase6 Task2，当前工作区）

本次完成了 Phase6 Task2（观战进度条与跳帧）：

- 观战播放栏新增时间线进度条 `ProgressSlider`
- 新增跳帧按钮：`-10f` / `+10f`
- 新增 seek 能力：拖动进度条可跳转到指定时间线帧
- 保持原有暂停/继续与倍速（1x/2x/4x）功能
- 新增 `observe_playback_seek_test.gd` 覆盖跳帧与进度条行为

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase6-observe-timeline-navigation.md`

验证结果（当前工作区）：

- 关键链路 smoke：`tests/app_flow_smoke_test.gd` 通过
- 全量测试：`tests/*.gd` 共 32 项，`32/32` 通过

## 本次改动（2026-03-30，Phase6 Task3，当前工作区）

本次完成了 Phase6 Task3（长时间线与复杂事件组合回归）：

- 新增复杂事件组合稳定性回归：`runtime_event_combo_stability_test.gd`
- 新增长时间线（6000 tick）稳定性回归：`runtime_event_long_timeline_stability_test.gd`
- 重点覆盖事件 `warning -> resolve` 阶段稳定性、响应策略触发与日志规模稳定性

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase6-runtime-stability-regression.md`

验证结果（当前工作区）：

- 关键链路 smoke：`tests/app_flow_smoke_test.gd` 通过
- 全量测试：`tests/*.gd` 共 34 项，`34/34` 通过

## 本次改动（2026-03-30，Phase7 Task1，当前工作区）

本次完成了 Phase7 Task1（runtime 属性驱动结算）：

- `battle_combat_system` 从固定 tick 结束，升级为基于单位属性的实时结算：
  - 按最近敌方目标选择
  - 按攻击射程判定可攻击
  - 按攻击速度生成冷却 tick
  - 按攻击力结算伤害与击杀
- 接入战技被动效果 `ally_tag_attack_shift`（`虚无回响`）到攻击力计算
- `battle_ai_system` 升级为追踪最近敌方并在射程外推进，避免纯直线穿越
- `observe_screen` 播放逻辑改为累积器循环消费，支持较长时间线稳定播放
- 新增 combat 回归测试：
  - `runtime_combat_attr_driven_test.gd`
  - `runtime_combat_strategy_effect_test.gd`

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase7-runtime-combat-attr.md`

验证结果（当前工作区）：

- 关键链路 smoke：`tests/app_flow_smoke_test.gd` 通过
- 全量测试：`tests/*.gd` 共 36 项，`36/36` 通过

## 本次改动（2026-03-30，Phase7 Task2，当前工作区）

本次完成了 Phase7 Task2（内容层多事件配置入口）：

- `battle_content` 新增事件：
  - `evt_demon_ambush`
  - `evt_void_collapse`
- `battle_content` 新增 battle 级多事件组合：
  - `battle_void_gate_beta`（`event_ids` 直接配置多事件）
- 新增 test pack：
  - `pack_multi_event_beta`
- 新增集成回归：
  - `runtime_multi_event_content_battle_test.gd`（直接走 runner 验证内容层多事件）
- 扩展一致性回归：
  - `content_consistency_test.gd` 新增 pack battle_id 与 battle event_id 引用校验

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase7-content-multi-event.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 37 项，`37/37` 通过

## 本次改动（2026-03-30，Phase7 Task3，当前工作区）

本次完成了 Phase7 Task3（主动战技 runtime 生效链路）：

- `battle_combat_system` 新增主动战技冷却运行时状态（`strategy_runtime`）
- 实装主动战技效果：
  - `enemy_group_slow`（`strat_chill_wave`）
  - `enemy_front_nuke`（`strat_nuclear_strike`）
- 新增策略施放日志：`log_entries.type = strategy_cast`
- `battle_ai_system` 去除占位触发逻辑，改为消费减速状态参与移动
- `battle_state` 补齐 `base_move_speed/slow_ratio/slow_ticks_remaining` 实体字段
- 新增回归测试：
  - `runtime_active_strategy_trigger_test.gd`
  - `runtime_active_strategy_nuke_effect_test.gd`

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase7-active-strategy-runtime.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 39 项，`39/39` 通过

## 本次改动（2026-03-30，Phase8 Task1，当前工作区）

本次完成了 Phase8 Task1（观战事件时间线可视化）：

- `ObserveScreen` 新增事件面板：
  - `EventFilterSelect`（全部/仅预警/仅结算/仅战技）
  - `EventTimelineLabel`（事件标记时间线文本）
- 新增事件筛选逻辑，筛选结果同时作用于：
  - 时间线标记展示
  - 当前 tick 的事件 HUD 文本
- 新增回归测试：
  - `observe_event_timeline_filter_test.gd`
- 扩展播放控件 smoke 测试，覆盖事件面板节点存在性

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase8-observe-event-timeline.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 40 项，`40/40` 通过

## 本次改动（2026-03-30，Phase8 Task2，当前工作区）

本次完成了 Phase8 Task2（观战 HUD 战技施放反馈）：

- 在观战 HUD 新增战技施放文本行（`StrategyCastLabel`）
- 每个 tick 从 `log_entries.type = strategy_cast` 汇总当帧施放战技并显示
- 事件筛选逻辑保持独立，战技施放反馈不被事件筛选吞掉
- 新增回归测试：
  - `observe_strategy_cast_hud_test.gd`

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase8-observe-strategy-feedback.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 41 项，`41/41` 通过

## 本次改动（2026-03-30，Phase8 Task3，当前工作区）

本次完成了 Phase8 Task3（事件标记点与跳转联动）：

- 事件面板新增 `EventMarkerList`，按当前筛选条件展示事件 tick 标记
- 点击标记可直接跳转到对应 tick（复用 observe 现有 seek 通道）
- 新增回归测试：
  - `observe_event_marker_jump_test.gd`
- 扩展播放控件测试，覆盖标记列表节点存在性

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase8-event-marker-jump.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 42 项，`42/42` 通过

## 本次改动（2026-03-30，Phase9 Task1，当前工作区）

本次完成了 Phase9 Task1（性能与稳定性基准）：

- 新增基准工具：
  - `tools/runtime_benchmark.gd`
  - 支持多场景多轮执行、耗时统计、确定性校验、问题汇总
- 新增基准回归测试：
  - `runtime_benchmark_stability_test.gd`
  - 覆盖高叠加场景（多战技 + 多事件）下的运行状态、耗时阈值与确定性

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase9-runtime-benchmark.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 43 项，`43/43` 通过

## 本次改动（2026-03-30，Phase9 Task2，当前工作区）

本次完成了 Phase9 Task2（结果页关键施放战技摘要）：

- 结果页新增 `StrategyCastSummaryLabel`
- `build_summary` 新增 `strategy_cast_lines`，从 `log_entries.strategy_cast` 聚合输出 `strategy_id xN`
- 新增回归测试：
  - `result_strategy_cast_summary_test.gd`
- 扩展结果页字段与 UI smoke 测试，覆盖新字段与节点

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase9-result-strategy-summary.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 44 项，`44/44` 通过

## 本次改动（2026-03-30，Phase9 Task3，当前工作区）

本次完成了 Phase9 Task3（结果页战斗配置快照）：

- 结果页新增 `SetupSnapshotLabel`
- `build_summary` 新增 `setup_snapshot_lines`，从 `battle_setup` 输出：
  - `hero_id`
  - `ally_ids`
  - `strategy_ids`
  - `battle_id`
  - `seed`
- 新增回归测试：
  - `result_setup_snapshot_test.gd`
- 扩展结果页字段与 UI smoke 测试，覆盖快照字段与节点

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase9-result-setup-snapshot.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 45 项，`45/45` 通过

## 本次改动（2026-03-30，Phase10 Task1，当前工作区）

本次完成了 Phase10 Task1（观战时间轴缩放与密度控制）：

- 观战事件面板新增控件：
  - `EventTimelineZoomSelect`（时间轴缩放 1x/2x/5x）
  - `EventTimelineDensitySelect`（标记密度 高/中/低）
- 事件时间线渲染链路升级为：
  - 事件筛选
  - 时间桶聚合（按缩放倍率）
  - 密度抽样（按密度上限）
  - 时间线文本与标记列表渲染
- 新增查询接口：
  - `get_event_timeline_marker_count`
- 新增回归测试：
  - `observe_timeline_zoom_density_test.gd`
- 扩展播放控件 smoke 测试，覆盖新增控件节点存在性

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase10-observe-timeline-zoom-density.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 46 项，`46/46` 通过

## 本次改动（2026-03-30，Phase10 Task2，当前工作区）

本次完成了 Phase10 Task2（基准结果 CSV 导出与历史阈值对比）：

- `runtime_benchmark` 新增导出能力：
  - `build_summary_csv(summary)` 输出 `scenario_id,iterations,avg_ms,max_ms,deterministic_ok,status_counts_json`
  - 内置 CSV 字段转义（逗号/引号/换行）
- `runtime_benchmark` 新增历史对比能力：
  - `compare_with_baseline(current_summary, baseline_summary, allowed_ratio_threshold)`
  - 校验全局 `avg_run_ms/max_run_ms` 与场景级 `avg_ms/max_ms`
  - 当 baseline 的 `deterministic_ok=true` 且当前退化时输出问题
- `run_scenarios` 增加可选参数，支持直接接入 baseline 比较输出 issues
- 新增回归测试：
  - `runtime_benchmark_csv_threshold_test.gd`
- 扩展稳定性测试，覆盖 CSV 导出结构

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase10-benchmark-csv-threshold.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 47 项，`47/47` 通过

## 本次改动（2026-03-30，Phase11 Task1，当前工作区）

本次完成了 Phase11 Task1（benchmark CSV 命令行导出与门禁）：

- 新增 benchmark 导出服务：
  - `tools/export_runtime_benchmark.gd`
  - 能力包括：
    - 默认 benchmark 场景
    - 命令行参数解析（output/summary-json/baseline/max-ms/ratio）
    - 输出 CSV 与 summary JSON 文件
    - baseline JSON 读取并接入阈值对比
    - 根据 `issues` 返回 `exit_code`（0/1）
- 新增命令行入口：
  - `tools/export_runtime_benchmark_cli.gd`
  - 支持 headless 直接执行并以进程退出码表达门禁结果
- 新增回归测试：
  - `runtime_benchmark_cli_export_gate_test.gd`
- 已执行 CLI smoke：
  - `--script res://tools/export_runtime_benchmark_cli.gd -- --output=... --max-ms=5000 --ratio=10`

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase11-benchmark-cli-gate.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 48 项，`48/48` 通过

## 本次改动（2026-03-30，Phase11 Task2，当前工作区）

本次完成了 Phase11 Task2（baseline 策略与预提交门禁接入）：

- `export_runtime_benchmark` 新增 baseline 策略参数：
  - `--baseline-profile`
  - `--baseline-root`
  - `--write-baseline`
  - `--require-baseline`
- 新增 baseline 路径解析能力：
  - `resolve_baseline_path(profile, baseline_root_path)`
- 新增 baseline 策略回归测试：
  - `runtime_benchmark_baseline_profile_test.gd`
- 新增预提交门禁脚本：
  - `tools/run_benchmark_gate.sh`
  - `.githooks/pre-commit`
  - `tools/install_git_hooks.sh`
- 新增主 baseline 文件：
  - `data/benchmarks/runtime_benchmark_baseline_main.json`
- 新增 baseline 管理文档：
  - `docs/benchmark-baseline-policy.md`
- README 增补 benchmark 门禁用法

对应新增计划文档：

- `docs/superpowers/plans/2026-03-30-godlingbattle-phase11-baseline-policy-precommit-gate.md`

验证结果（当前工作区）：

- 全量测试：`tests/*.gd` 共 49 项，`49/49` 通过

## 本次改动（2026-03-30，Phase12 Task1，当前工作区）

本次完成了 Phase12 Task1（CI benchmark 远端门禁接入）：

- 新增 CI workflow：
  - `.github/workflows/benchmark-gate.yml`
  - 在 `pull_request`、`push(main)`、`workflow_dispatch` 触发 benchmark 门禁
- 工作流接入 Linux 环境 Godot 安装与 `GODOT_BIN` 解析（`godot/godot4` 双通道）
- 工作流执行 `tools/run_benchmark_gate.sh`，与本地 pre-commit 门禁保持一致策略
- 新增 workflow 配置回归测试：
  - `tests/ci_benchmark_gate_workflow_test.gd`
- 新增 Phase12 计划文档：
  - `docs/superpowers/plans/2026-03-30-godlingbattle-phase12-ci-benchmark-gate.md`

验证结果（当前工作区）：

- 新增测试：`tests/ci_benchmark_gate_workflow_test.gd` 通过
- benchmark 相关回归通过：
  - `tests/runtime_benchmark_stability_test.gd`
  - `tests/runtime_benchmark_csv_threshold_test.gd`
  - `tests/runtime_benchmark_cli_export_gate_test.gd`
  - `tests/runtime_benchmark_baseline_profile_test.gd`
- 全量测试：`tests/*.gd` 共 50 项，`50/50` 通过

## 本次改动（2026-03-30，Phase13 Task1-Task4，当前工作区）

本次完成了 Phase13（结果页中文化兜底 + 观战战报中心化）：

- Task1（共享显示名解析器）：
  - 新增 `scripts/ui/display_name_resolver.gd`
  - 新增 `tests/display_name_resolver_test.gd`
  - 统一处理 `unit/event/strategy/battle/entity_id` 到中文显示名与中文兜底
- Task2（结果页去英文 ID）：
  - `scripts/result/result_screen.gd` 全链路接入 resolver
  - 结果页存活/阵亡/事件/战技/关键施放/配置快照不再泄露 `hero_/ally_/enemy_/strat_/battle_`
  - 新增/更新测试：
    - `tests/result_localization_no_english_ids_test.gd`
    - `tests/result_setup_snapshot_test.gd`
    - `tests/result_strategy_cast_summary_test.gd`
- Task3（观战双层战报中心）：
  - 新增 `scripts/observe/battle_report_formatter.gd`
  - `Observe` 右侧新增 `DetailToggleButton + DetailLogList`，默认折叠、可展开战术明细
  - 简报/明细与 tick 与筛选联动，日志文案中文化并补充“何时释放何技能/何时事件结算”
  - 新增/更新测试：
    - `tests/observe_battle_report_brief_detail_test.gd`
    - `tests/observe_event_timeline_filter_test.gd`
- Task3 修复收口（代码质量复评问题）：
  - 修复战况总览进度帧刷新慢一拍
  - 修复空态文案为 `战况总览：数据准备中`
  - 新增回归：`tests/observe_battle_overview_state_sync_test.gd`
- 对应 Phase13 设计与计划文档：
  - `docs/superpowers/specs/2026-03-30-godlingbattle-battle-report-center-design.md`
  - `docs/superpowers/plans/2026-03-30-godlingbattle-phase13-battle-report-center.md`

对应提交：

- `442a661`（feat: add shared display name resolver for localized battle logs）
- `b82fe55`（fix: remove raw english ids from result summary output）
- `a3f4477`（test: align result cast summary assertions with localized names）
- `5e2b12a`（feat: add dual-layer observe battle report center）
- `0342141`（fix: sync observe overview progress and empty-state text）

