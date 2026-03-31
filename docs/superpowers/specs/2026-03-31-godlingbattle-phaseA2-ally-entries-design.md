# GodlingBattle Phase A2 多友方体系（ally_entries）设计

## 1. 背景

A1 已完成多敌人关卡矩阵，但 1.6「多友方测试」仍未落地。当前友军编排主要依赖 `ally_ids`（重复 id 表示数量），缺少显式“数量单位”语义与“个体友方/远近混搭”配置表达。

## 2. 目标与边界

### 2.1 目标

1. 引入 `ally_entries`（`{unit_id, count}`）作为 A2 的主编排输入。
2. 支持三类 A2 预设：
- 数量友方（同单位多数量）
- 个体友方（少量异构单位）
- 远近混搭友方（近战+远程）
3. 保持旧 `ally_ids` 路径可继续运行（兼容模式）。

### 2.2 非目标

1. 不在 A2 实现策略流派（防御流）——留给后续 B 阶段。
2. 不改 battle_result 字段结构。
3. 不在 A2 引入新战斗交互方式。

## 3. 方案与决策

用户确认采用：**堆叠语义（count）**。

采用“最小侵入兼容方案”：

1. `battle_setup` 增加可选字段 `ally_entries`。
2. runtime 入口优先解析 `ally_entries`；缺省时回退 `ally_ids`。
3. 运行时内部仍使用现有实体数组，不改 combat/ai 结构。

这样可以让 A2 快速上线，同时不破坏已有测试与 A1 预设。

## 4. 数据结构

### 4.1 battle_setup 增补

新增可选字段：

- `ally_entries: Array[Dictionary]`
- 每项结构：
  - `unit_id: String`
  - `count: int`

示例：

```gdscript
"ally_entries": [
  {"unit_id": "ally_hound_remnant", "count": 3},
  {"unit_id": "ally_arc_shooter", "count": 1}
]
```

### 4.2 兼容规则

1. 当 `ally_entries` 非空时：
- 以 `ally_entries` 作为友军展开来源。
2. 当 `ally_entries` 为空或缺失时：
- 回退使用 `ally_ids`。
3. 对外返回/显示仍可保留 `ally_ids`，A2 UI 与测试优先验证 `ally_entries` 路径。

## 5. 校验规则

A2 继续沿用友军总数区间（`0..8`）：

1. `count <= 0` 视为非法。
2. `unit_id` 不存在视为 `missing_ally`。
3. `ally_entries` 展开总数超出 `MAX_ALLY_COUNT` 视为 `invalid_ally_count`。

错误优先级：先检查结构合法性，再检查 unit 存在性，再检查总数上限。

## 6. 内容扩展

为支持“个体友方 + 远近混搭”，新增至少 2 个友军单位：

1. `ally_arc_shooter`（远程友军）
- 低到中等血量，较远攻击距离

2. `ally_guardian_sentinel`（个体强力友军）
- 更高生存或更高单体输出，用于体现“个体友方”概念

现有 `ally_hound_remnant` 保留为数量单位模板。

## 7. 准备页（可见化）

在测试预设中新增 A2 入口：

1. `A2 多友方（数量单位）`
2. `A2 多友方（个体友方）`
3. `A2 多友方（远近混搭）`

应用预设后：

1. 写入 `ally_entries`。
2. 同步更新摘要文本，显示总友军数量与组成。
3. 仍可与现有 ally-count 下拉共存，但 A2 预设路径优先保证 `ally_entries` 可测。

## 8. 测试设计

### 8.1 runtime 新增

1. `runtime_ally_entries_expand_test.gd`
- 断言 `ally_entries` 按 count 正确展开到实体。

2. `runtime_ally_entries_mixed_role_test.gd`
- 断言远近混搭预设首帧同时存在近战与远程友军。

3. `runtime_ally_entries_individual_unit_test.gd`
- 断言个体友方预设包含 `ally_guardian_sentinel`。

### 8.2 preparation/UI 更新

1. 扩展 `preparation_test_mode_preset_test.gd`
- 断言 A2 三个预设存在。
- 应用预设后断言 `current_selection` 包含 `ally_entries`，且 battle/strategy 映射正确。

2. 兼容回归
- 保留已有 `preparation_variable_ally_count_test.gd` 与 `runtime_variable_ally_count_test.gd` 通过。

## 9. 验收标准

1. 出战前准备可见 A2 三个预设入口。
2. 应用 A2 任一预设后可正常开始战斗（非 invalid_setup）。
3. `ally_entries` 路径测试全部通过。
4. 旧 `ally_ids` 路径关键回归不退化。

## 10. 风险与缓解

1. 风险：`ally_entries` 与 `ally_ids` 双轨导致状态混乱。
- 缓解：明确优先级（entries > ids），并在 selection summary 显示最终展开结果。

2. 风险：准备页逻辑复杂度上升。
- 缓解：将 entries 解析封装成独立 helper，不把展开逻辑散落在多个函数。

3. 风险：新增单位平衡偏离。
- 缓解：A2 先确保“可测可区分”，数值精调留到后续 B/D 阶段。

## 11. 里程碑

Phase A2 完成定义：

1. `ally_entries` 编排链路可用。
2. 多友方三类预设可见且可运行。
3. A2 新增测试通过，既有回归保持通过。
4. `docs/HANDOFF.md` 记录 A2 进展。
