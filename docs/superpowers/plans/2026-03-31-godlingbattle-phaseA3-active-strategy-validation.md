# GodlingBattle Phase A3 Active Strategy Validation Implementation Plan

**Goal:** 完成 1.7 主动策略测试的预设入口、测试包和集成验证闭环。

## Task 1: A3 预设入口

- 修改 `scripts/prep/preparation_screen.gd`
- 新增 3 个预设常量与下拉入口
- 应用预设时写入对应 `strategy_ids`

## Task 2: A3 内容测试包

- 修改 `autoload/battle_content.gd`
- 新增 `pack_a3_active_chill` / `pack_a3_active_nuke` / `pack_a3_active_combo`

## Task 3: A3 测试补齐

- 新增 `tests/preparation_a3_active_preset_test.gd`
- 新增 `tests/content_a3_active_pack_presence_test.gd`
- 新增 `tests/runtime_active_strategy_effect_profile_test.gd`
- 新增 `tests/observe_active_strategy_vfx_integration_test.gd`
- 更新 `tests/preparation_test_mode_preset_test.gd`

## Task 4: 验证与交接

- 运行 A3 关键测试切片
- 更新 `docs/HANDOFF.md`
