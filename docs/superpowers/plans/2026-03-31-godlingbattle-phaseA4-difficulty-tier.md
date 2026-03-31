# GodlingBattle Phase A4 Difficulty Tier Implementation Plan

**Goal:** 落地 1.8 三档战斗力难度配置，并完成可见化与测试闭环。

## Task 1: A4 RED 测试

- 新增 `tests/preparation_a4_difficulty_preset_test.gd`
- 新增 `tests/content_a4_difficulty_matrix_presence_test.gd`
- 新增 `tests/runtime_a4_difficulty_curve_test.gd`

## Task 2: A4 配置实现

- 修改 `autoload/battle_content.gd`：新增 3 档 battle 与 3 个 pack
- 修改 `scripts/prep/preparation_screen.gd`：新增 3 个 A4 预设入口与映射

## Task 3: 回归与一致性

- 修改 `tests/preparation_test_mode_preset_test.gd`
- 修改 `tests/content_consistency_test.gd`
- 运行 A4 关键测试切片并确认通过

## Task 4: 文档同步

- 更新 `docs/HANDOFF.md`
