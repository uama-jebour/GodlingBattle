# GodlingBattle Phase A2 Ally Entries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `ally_entries` (`unit_id + count`) to support multi-ally quantity/individual/mixed presets while preserving `ally_ids` compatibility.

**Architecture:** Add optional `ally_entries` to setup/validation/runtime expansion with explicit precedence over `ally_ids`. Keep combat/runtime contracts unchanged by converting entries to existing entity rows before battle tick loops. Expose A2 presets in preparation UI and verify via runtime + preset tests.

**Tech Stack:** Godot 4.x, GDScript, headless SceneTree tests in `tests/*.gd`.

---

## File Structure

### Content definitions
- Modify: `autoload/battle_content.gd`
- Responsibility: add new ally unit defs and A2 test packs.

### Setup + runtime compatibility
- Modify: `scripts/prep/preparation_screen.gd`
- Modify: `scripts/battle_runtime/battle_runner.gd`
- Modify: `scripts/battle_runtime/battle_state.gd`
- Responsibility: validate `ally_entries`, expand entries to entities, preserve fallback to `ally_ids`.

### A2 behavior tests
- Create: `tests/runtime_ally_entries_expand_test.gd`
- Create: `tests/runtime_ally_entries_mixed_role_test.gd`
- Create: `tests/runtime_ally_entries_individual_unit_test.gd`
- Modify: `tests/preparation_test_mode_preset_test.gd`
- Modify: `tests/content_consistency_test.gd`

### Handoff
- Modify: `docs/HANDOFF.md`

---

### Task 1: Add RED Tests for ally_entries Runtime Expansion

**Files:**
- Create: `tests/runtime_ally_entries_expand_test.gd`
- Create: `tests/runtime_ally_entries_mixed_role_test.gd`
- Create: `tests/runtime_ally_entries_individual_unit_test.gd`

- [ ] **Step 1: Write failing expansion-count test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 3}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033201
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var ally_count := 0
	for row in (timeline[0] as Dictionary).get("entities", []):
		var side := str((row as Dictionary).get("side", ""))
		if side == "ally":
			ally_count += 1
	if ally_count != 3:
		_failures.append("expected 3 ally entities from ally_entries, got %d" % ally_count)
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Write failing mixed-role ally test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 2},
			{"unit_id": "ally_arc_shooter", "count": 1}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033202
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_melee_ally := false
	var has_ranged_ally := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var d := row as Dictionary
		if str(d.get("side", "")) != "ally":
			continue
		var uid := str(d.get("unit_id", ""))
		if uid == "ally_hound_remnant":
			has_melee_ally = true
		if uid == "ally_arc_shooter":
			has_ranged_ally = true
	if not has_melee_ally:
		_failures.append("expected melee ally in mixed role setup")
	if not has_ranged_ally:
		_failures.append("expected ranged ally in mixed role setup")
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 3: Write failing individual-ally test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_guardian_sentinel", "count": 1}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033203
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_guardian := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var d := row as Dictionary
		if str(d.get("side", "")) != "ally":
			continue
		if str(d.get("unit_id", "")) == "ally_guardian_sentinel":
			has_guardian = true
			break
	if not has_guardian:
		_failures.append("expected ally_guardian_sentinel in first frame")
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 4: Run three tests to confirm RED**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_expand_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_mixed_role_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_individual_unit_test.gd`

Expected: FAIL before ally_entries parsing + new ally units are implemented.

---

### Task 2: Implement ally_entries Parsing/Validation/Expansion

**Files:**
- Modify: `scripts/prep/preparation_screen.gd`
- Modify: `scripts/battle_runtime/battle_runner.gd`
- Modify: `scripts/battle_runtime/battle_state.gd`

- [ ] **Step 1: Add helper to normalize ally entries in preparation**

```gdscript
func _normalize_ally_entries(selection: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw in selection.get("ally_entries", []):
		var row := raw as Dictionary
		var unit_id := str(row.get("unit_id", ""))
		var count := int(row.get("count", 0))
		if unit_id.is_empty() or count <= 0:
			continue
		rows.append({"unit_id": unit_id, "count": count})
	return rows
```

- [ ] **Step 2: Validate ally_entries with precedence over ally_ids**

```gdscript
# inside build_battle_setup(selection)
var ally_entries: Array[Dictionary] = _normalize_ally_entries(selection)
var ally_ids: Array = selection.get("ally_ids", [])

if not ally_entries.is_empty():
	var total := 0
	for entry in ally_entries:
		total += int(entry.get("count", 0))
		if content.get_unit(str(entry.get("unit_id", ""))).is_empty():
			content.free()
			return {"invalid_reason": "missing_ally"}
	if total < MIN_ALLY_COUNT or total > MAX_ALLY_COUNT:
		content.free()
		return {"invalid_reason": "invalid_ally_count"}
else:
	if not _is_valid_ally_count(ally_ids):
		content.free()
		return {"invalid_reason": "invalid_ally_count"}
```

- [ ] **Step 3: Persist ally_entries into setup payload**

```gdscript
return {
	"hero_id": hero_id,
	"ally_ids": ally_ids.duplicate(),
	"ally_entries": ally_entries.duplicate(true),
	"strategy_ids": strategy_ids.duplicate(),
	"battle_id": battle_id,
	"seed": int(selection.get("seed", 0)),
	"randomized_spawn": bool(selection.get("randomized_spawn", false))
}
```

- [ ] **Step 4: Update runtime setup validation for ally_entries**

```gdscript
# in battle_runner._validate_setup
var ally_entries: Array = setup.get("ally_entries", [])
if not ally_entries.is_empty():
	var total := 0
	for raw in ally_entries:
		var entry := raw as Dictionary
		var unit_id := str(entry.get("unit_id", ""))
		var count := int(entry.get("count", 0))
		if unit_id.is_empty() or count <= 0:
			content.free()
			return "invalid_ally_count"
		if content.get_unit(unit_id).is_empty():
			content.free()
			return "missing_ally"
		total += count
	if total < MIN_ALLY_COUNT or total > MAX_ALLY_COUNT:
		content.free()
		return "invalid_ally_count"
else:
	# keep existing ally_ids validation path
```

- [ ] **Step 5: Expand ally_entries in battle_state spawn path**

```gdscript
func _resolved_ally_ids(setup: Dictionary) -> Array[String]:
	var ally_entries: Array = setup.get("ally_entries", [])
	if ally_entries.is_empty():
		var ids: Array[String] = []
		for ally_id in setup.get("ally_ids", []):
			ids.append(str(ally_id))
		return ids
	var expanded: Array[String] = []
	for raw in ally_entries:
		var entry := raw as Dictionary
		var unit_id := str(entry.get("unit_id", ""))
		var count := int(entry.get("count", 0))
		for _i in range(count):
			expanded.append(unit_id)
	return expanded

# in _spawn_entities_from_setup()
for ally_id in _resolved_ally_ids(setup):
	...
```

- [ ] **Step 6: Run RED tests again to confirm missing-unit failure only**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_expand_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_mixed_role_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_individual_unit_test.gd`

Expected: first test likely PASS; latter tests still FAIL due to missing new ally unit defs.

---

### Task 3: Add New Ally Units and A2 Test Packs

**Files:**
- Modify: `autoload/battle_content.gd`
- Modify: `tests/content_consistency_test.gd`

- [ ] **Step 1: Add `ally_arc_shooter` and `ally_guardian_sentinel` unit defs**

```gdscript
"ally_arc_shooter": TYPES.unit({
	"unit_id": "ally_arc_shooter",
	"display_name": "弧矢游侠",
	"type": "normal",
	"move_mode": "walking",
	"attack_mode": "ranged",
	"move_speed": 11.0,
	"radius": 2.0,
	"max_hp": 24.0,
	"attack_power": 2.2,
	"attack_speed": 1.3,
	"attack_range": 3.8,
	"tags": ["远程", "游侠"],
	"move_logic": "chase_nearest",
	"combat_ai": "ranged"
}),
"ally_guardian_sentinel": TYPES.unit({
	"unit_id": "ally_guardian_sentinel",
	"display_name": "守望壁垒",
	"type": "normal",
	"move_mode": "walking",
	"attack_mode": "melee",
	"move_speed": 8.0,
	"radius": 2.8,
	"max_hp": 54.0,
	"attack_power": 3.4,
	"attack_speed": 1.0,
	"attack_range": 1.1,
	"tags": ["守卫"],
	"move_logic": "chase_nearest",
	"combat_ai": "melee"
})
```

- [ ] **Step 2: Add A2 packs with ally_entries**

```gdscript
{
	"pack_id": "pack_a2_quantity_allies",
	"battle_id": "battle_void_gate_alpha",
	"hero_id": "hero_angel",
	"ally_ids": [],
	"ally_entries": [{"unit_id": "ally_hound_remnant", "count": 4}],
	"strategy_ids": []
},
{
	"pack_id": "pack_a2_individual_allies",
	"battle_id": "battle_void_gate_alpha",
	"hero_id": "hero_angel",
	"ally_ids": [],
	"ally_entries": [{"unit_id": "ally_guardian_sentinel", "count": 1}],
	"strategy_ids": []
},
{
	"pack_id": "pack_a2_mixed_allies",
	"battle_id": "battle_void_gate_alpha",
	"hero_id": "hero_angel",
	"ally_ids": [],
	"ally_entries": [
		{"unit_id": "ally_hound_remnant", "count": 2},
		{"unit_id": "ally_arc_shooter", "count": 1}
	],
	"strategy_ids": []
}
```

- [ ] **Step 3: Extend consistency checks for ally_entries**

```gdscript
for pack in content.get_test_packs():
	for ally_entry_raw in pack.get("ally_entries", []):
		var ally_entry := ally_entry_raw as Dictionary
		var unit_id := str(ally_entry.get("unit_id", ""))
		if content.get_unit(unit_id).is_empty():
			_failures.append("missing ally entry unit: %s" % unit_id)
		if int(ally_entry.get("count", 0)) <= 0:
			_failures.append("invalid ally entry count in pack: %s" % str(pack.get("pack_id", "")))
```

- [ ] **Step 4: Run three runtime tests + consistency to confirm GREEN**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_expand_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_mixed_role_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_individual_unit_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/content_consistency_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add autoload/battle_content.gd tests/content_consistency_test.gd scripts/battle_runtime/battle_runner.gd scripts/battle_runtime/battle_state.gd scripts/prep/preparation_screen.gd tests/runtime_ally_entries_expand_test.gd tests/runtime_ally_entries_mixed_role_test.gd tests/runtime_ally_entries_individual_unit_test.gd
git commit -m "feat: add ally_entries runtime path and multi-ally content"
```

---

### Task 4: Expose A2 Presets in Preparation and Verify UI Path

**Files:**
- Modify: `scripts/prep/preparation_screen.gd`
- Modify: `tests/preparation_test_mode_preset_test.gd`

- [ ] **Step 1: Add A2 preset constants + dropdown options**

```gdscript
const PRESET_A2_QUANTITY_ALLIES := "preset_a2_quantity_allies"
const PRESET_A2_INDIVIDUAL_ALLIES := "preset_a2_individual_allies"
const PRESET_A2_MIXED_ALLIES := "preset_a2_mixed_allies"

_add_test_preset_option(9, "测试预设：A2 多友方（数量单位）", PRESET_A2_QUANTITY_ALLIES)
_add_test_preset_option(10, "测试预设：A2 多友方（个体友方）", PRESET_A2_INDIVIDUAL_ALLIES)
_add_test_preset_option(11, "测试预设：A2 多友方（远近混搭）", PRESET_A2_MIXED_ALLIES)
```

- [ ] **Step 2: Add preset apply branches writing ally_entries**

```gdscript
PRESET_A2_QUANTITY_ALLIES:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": [],
		"ally_entries": [{"unit_id": "ally_hound_remnant", "count": 4}],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha"
	}
PRESET_A2_INDIVIDUAL_ALLIES:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": [],
		"ally_entries": [{"unit_id": "ally_guardian_sentinel", "count": 1}],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha"
	}
PRESET_A2_MIXED_ALLIES:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": [],
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 2},
			{"unit_id": "ally_arc_shooter", "count": 1}
		],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha"
	}
```

- [ ] **Step 3: Ensure selection summary can render ally_entries fallback**

```gdscript
func _selection_ally_ids(current_selection: Dictionary) -> Array:
	var ally_entries: Array = current_selection.get("ally_entries", [])
	if ally_entries.is_empty():
		return current_selection.get("ally_ids", [])
	var expanded: Array = []
	for raw in ally_entries:
		var entry := raw as Dictionary
		for _i in range(int(entry.get("count", 0))):
			expanded.append(str(entry.get("unit_id", "")))
	return expanded

# use _selection_ally_ids() in _format_selection_summary
```

- [ ] **Step 4: Extend preset UI test for A2**

```gdscript
if _find_metadata_index(preset_select, "preset_a2_quantity_allies") < 0:
	_failures.append("expected preset_a2_quantity_allies")
if _find_metadata_index(preset_select, "preset_a2_individual_allies") < 0:
	_failures.append("expected preset_a2_individual_allies")
if _find_metadata_index(preset_select, "preset_a2_mixed_allies") < 0:
	_failures.append("expected preset_a2_mixed_allies")

var a2_index := _find_metadata_index(preset_select, "preset_a2_mixed_allies")
if a2_index >= 0:
	preset_select.select(a2_index)
	preset_select.item_selected.emit(a2_index)
	apply_preset_button.pressed.emit()
	await process_frame
	var current_selection: Dictionary = screen.call("get_current_selection")
	var ally_entries: Array = current_selection.get("ally_entries", [])
	if ally_entries.size() < 2:
		_failures.append("A2 mixed preset should set ally_entries")
```

- [ ] **Step 5: Run prep tests and commit**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_controls_smoke_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_test_mode_preset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_variable_ally_count_test.gd`

Expected: PASS.

```bash
git add scripts/prep/preparation_screen.gd tests/preparation_test_mode_preset_test.gd
git commit -m "feat: add phase A2 ally-entry presets in preparation"
```

---

### Task 5: A2 Regression Slice + Handoff

**Files:**
- Modify: `docs/HANDOFF.md`

- [ ] **Step 1: Run A2 regression slice**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_expand_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_mixed_role_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ally_entries_individual_unit_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_test_mode_preset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/content_consistency_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_variable_ally_count_test.gd`

Expected: all PASS.

- [ ] **Step 2: Update handoff block**

```markdown
## 本次改动（2026-03-31，Phase A2 多友方 ally_entries）
- 新增 ally_entries（unit_id+count）编排路径，优先级高于 ally_ids
- 新增友军单位：ally_arc_shooter / ally_guardian_sentinel
- 新增 A2 预设：数量单位/个体友方/远近混搭
- 新增 runtime 测试：ally_entries_expand / mixed_role / individual_unit
- 兼容回归通过：runtime_variable_ally_count + preparation 预设测试
```

- [ ] **Step 3: Commit docs**

```bash
git add docs/HANDOFF.md
git commit -m "docs: record phase A2 ally entries rollout"
```

---

## Self-Review

### Spec coverage check
- ally_entries 结构与优先级：Task 2
- 多友方三类预设：Task 4
- 新友军单位与内容支持：Task 3
- runtime/UI 验证与兼容守卫：Task 1 + Task 5

### Placeholder scan
- 无 TBD/TODO/implement later。
- 每个实现步骤给出具体代码片段与命令。

### Type consistency
- 字段统一：`ally_entries` + `{unit_id,count}`。
- preset id 统一：`preset_a2_*`。
- 测试命名统一：`runtime_ally_entries_*_test.gd`。
