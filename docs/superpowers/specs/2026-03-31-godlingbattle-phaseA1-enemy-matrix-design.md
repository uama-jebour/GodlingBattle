# GodlingBattle Phase A1 多敌人关卡矩阵设计

## 1. 背景

当前测试体系已具备基础编排能力（可变 ally、测试预设、事件召唤落点），但 1.4「多敌人测试」仍缺少结构化关卡矩阵。需要先以“关卡编排”方式补齐：近战、远程、混合、精英四类敌方压力模型。

## 2. 目标与范围

### 2.1 目标

1. 新增可直接运行的四类敌方测试关卡：
- 全近战
- 全远程
- 近远混合
- 精英主导
2. 在准备页测试预设中暴露上述关卡，确保“运行程序可见”。
3. 增加 runtime 测试，验证各关卡敌方构成与关键行为特征。

### 2.2 非目标

1. 不扩展友方体系（数量单位/个体友方）——该部分留到 Phase A2。
2. 不改 runtime 契约（`battle_setup` / `battle_result` 字段保持不变）。
3. 不改主流程（`出战前准备 -> 自动观战 -> 结果结算`）。

## 3. 方案选择

采用“关卡矩阵优先”方案（用户确认 A1）：

1. 先用 battle 配置表达敌方差异，不先改单位系统。
2. 优先复用现有敌方单位：
- 近战：`enemy_wandering_demon`
- 远程：`enemy_animated_machine`
- 精英：`enemy_hunter_fiend`
3. 若现有单位已能表达差异，则不新增新单位，遵循 YAGNI。

## 4. 新增关卡矩阵

在 `autoload/battle_content.gd` 新增：

1. `battle_test_enemy_melee`
- 敌方：全近战组合（复数 `enemy_wandering_demon`）

2. `battle_test_enemy_ranged`
- 敌方：全远程组合（复数 `enemy_animated_machine`）

3. `battle_test_enemy_mixed`
- 敌方：近远混合（`enemy_wandering_demon + enemy_animated_machine` 组合）

4. `battle_test_enemy_elite`
- 敌方：以 `enemy_hunter_fiend` 为核心，搭配少量护卫

命名原则：`battle_test_enemy_<type>`，避免与正式章节关卡命名冲突。

## 5. 准备页可见化要求

在 `scripts/prep/preparation_screen.gd` 的测试预设中新增 A1 入口：

1. `A1 多敌人：全近战`
2. `A1 多敌人：全远程`
3. `A1 多敌人：近远混合`
4. `A1 多敌人：精英主导`

点击“应用测试预设”后应直接写入：

- `battle_id` 为对应 A1 关卡
- ally 数量维持 A1 默认（建议 `2`）
- strategy 使用中性默认（建议 `[]` 或 `strat_void_echo`，以测试稳定性为先）

## 6. 测试设计

新增测试文件：

1. `tests/runtime_enemy_matrix_melee_test.gd`
- 断言首帧敌方均为近战单位。

2. `tests/runtime_enemy_matrix_ranged_test.gd`
- 断言首帧敌方均为远程单位。

3. `tests/runtime_enemy_matrix_mixed_test.gd`
- 断言首帧同时存在近战与远程单位。

4. `tests/runtime_enemy_matrix_elite_test.gd`
- 断言首帧存在精英单位 `enemy_hunter_fiend`。

5. 更新 `tests/preparation_test_mode_preset_test.gd`
- 断言测试预设列表包含 A1 四个入口。
- 至少验证一个 A1 预设应用后 `battle_id` 正确落地。

6. 更新 `tests/content_consistency_test.gd`
- 覆盖新增 battle ids 与对应 test packs 可解析。

## 7. 验收标准

1. 程序运行后，准备页能看到 A1 四个新预设。
2. 选择任一 A1 预设并开始战斗，不出现 invalid_setup。
3. A1 相关 runtime 测试与准备页预设测试全部通过。
4. 既有关键回归不退化：
- `tests/runtime_event_unresolved_summon_spawn_test.gd`
- `tests/preparation_controls_smoke_test.gd`
- `tests/preparation_test_mode_preset_test.gd`

## 8. 风险与缓解

1. 风险：仅用现有单位导致四类体感差异不足。
- 缓解：先通过数量与编排拉开差异；若仍不足，在 A1 收尾时补最小新单位。

2. 风险：预设数量增加导致维护成本上升。
- 缓解：统一 `PRESET_*` 命名并集中在 `_rebuild_test_preset_options + _apply_test_preset` 两处维护。

3. 风险：测试只验证组成，不验证战斗行为。
- 缓解：A1 保证“组成可测”；行为深度验证留在后续 B/C/D 阶段。

## 9. 里程碑

Phase A1 完成定义：

1. 多敌人关卡矩阵（4类）已落地。
2. 准备页预设可见并可一键应用。
3. A1 相关测试全部通过。
4. `docs/HANDOFF.md` 记录本轮结果。
