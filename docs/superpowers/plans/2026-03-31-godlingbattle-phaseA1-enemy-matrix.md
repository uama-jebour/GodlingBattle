# GodlingBattle Phase A1 Enemy Matrix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a runnable/testable multi-enemy matrix (melee/ranged/mixed/elite) and expose it in 出战前准备 test presets.

**Architecture:** Keep runtime contracts unchanged and express A1 entirely through content orchestration + prep preset wiring + focused runtime assertions. Add four new test battles in `battle_content.gd`, extend prep preset options in `preparation_screen.gd`, and gate with runtime composition tests plus existing prep/content regression guards.

**Tech Stack:** Godot 4.x, GDScript, headless SceneTree tests in `tests/*.gd`.

---

## File Structure

### Enemy matrix content
- Modify: `autoload/battle_content.gd`
- Responsibility: add 4 `battle_test_enemy_*` definitions and A1 test packs.

### Prep preset exposure
- Modify: `scripts/prep/preparation_screen.gd`
- Responsibility: add 4 A1 preset ids/options and map each to a concrete `battle_id`.

### Runtime matrix verification
- Create: `tests/runtime_enemy_matrix_melee_test.gd`
- Create: `tests/runtime_enemy_matrix_ranged_test.gd`
- Create: `tests/runtime_enemy_matrix_mixed_test.gd`
- Create: `tests/runtime_enemy_matrix_elite_test.gd`
- Responsibility: assert first-frame enemy composition for each matrix battle.

### UI/content consistency guards
- Modify: `tests/preparation_test_mode_preset_test.gd`
- Modify: `tests/content_consistency_test.gd`
- Responsibility: assert preset visibility/apply path and content registry integrity.

### Handoff status
- Modify: `docs/HANDOFF.md`
- Responsibility: append A1 rollout status and test results.

---

### Task 1: Add Failing Enemy Matrix Runtime Tests

**Files:**
- Create: `tests/runtime_enemy_matrix_melee_test.gd`
- Create: `tests/runtime_enemy_matrix_ranged_test.gd`
- Create: `tests/runtime_enemy_matrix_mixed_test.gd`
- Create: `tests/runtime_enemy_matrix_elite_test.gd`

- [ ] **Step 1: Write failing melee composition test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_melee",
		"seed": 26033111
	})
	_assert_first_frame_enemy_units(payload.get("timeline", []), ["enemy_wandering_demon"])
	_finish()

func _assert_first_frame_enemy_units(timeline: Array, allowed_units: Array[String]) -> void:
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		return
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if not allowed_units.has(str(entity.get("unit_id", ""))):
			_failures.append("unexpected enemy unit in melee battle: %s" % str(entity.get("unit_id", "")))

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Write failing ranged composition test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_ranged",
		"seed": 26033112
	})
	_assert_first_frame_enemy_units(payload.get("timeline", []), ["enemy_animated_machine"])
	_finish()

func _assert_first_frame_enemy_units(timeline: Array, allowed_units: Array[String]) -> void:
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		return
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if not allowed_units.has(str(entity.get("unit_id", ""))):
			_failures.append("unexpected enemy unit in ranged battle: %s" % str(entity.get("unit_id", "")))

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 3: Write failing mixed composition test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_mixed",
		"seed": 26033113
	})
	var has_melee := false
	var has_ranged := false
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		var uid := str(entity.get("unit_id", ""))
		if uid == "enemy_wandering_demon":
			has_melee = true
		if uid == "enemy_animated_machine":
			has_ranged = true
	if not has_melee:
		_failures.append("mixed battle should include enemy_wandering_demon")
	if not has_ranged:
		_failures.append("mixed battle should include enemy_animated_machine")
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 4: Write failing elite composition test**

```gdscript
extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_elite",
		"seed": 26033114
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_elite := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if str(entity.get("unit_id", "")) == "enemy_hunter_fiend":
			has_elite = true
			break
	if not has_elite:
		_failures.append("elite battle should include enemy_hunter_fiend")
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 5: Run all 4 tests to confirm RED**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_melee_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_ranged_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_mixed_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_elite_test.gd`

Expected: FAIL because `battle_test_enemy_*` ids are not yet defined.

---

### Task 2: Implement Enemy Matrix Battles and Test Packs

**Files:**
- Modify: `autoload/battle_content.gd`
- Modify: `tests/content_consistency_test.gd`

- [ ] **Step 1: Add 4 matrix battles to content**

```gdscript
# in _battles
"battle_test_enemy_melee": TYPES.battle({
	"battle_id": "battle_test_enemy_melee",
	"display_name": "测试矩阵·全近战",
	"battlefield_id": "field_void_gate",
	"enemy_units": ["enemy_wandering_demon", "enemy_wandering_demon", "enemy_wandering_demon"],
	"event_ids": [],
	"seed": 26033111
}),
"battle_test_enemy_ranged": TYPES.battle({
	"battle_id": "battle_test_enemy_ranged",
	"display_name": "测试矩阵·全远程",
	"battlefield_id": "field_void_gate",
	"enemy_units": ["enemy_animated_machine", "enemy_animated_machine", "enemy_animated_machine"],
	"event_ids": [],
	"seed": 26033112
}),
"battle_test_enemy_mixed": TYPES.battle({
	"battle_id": "battle_test_enemy_mixed",
	"display_name": "测试矩阵·近远混合",
	"battlefield_id": "field_void_gate",
	"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine", "enemy_wandering_demon"],
	"event_ids": [],
	"seed": 26033113
}),
"battle_test_enemy_elite": TYPES.battle({
	"battle_id": "battle_test_enemy_elite",
	"display_name": "测试矩阵·精英主导",
	"battlefield_id": "field_void_gate",
	"enemy_units": ["enemy_hunter_fiend", "enemy_wandering_demon", "enemy_animated_machine"],
	"event_ids": [],
	"seed": 26033114
})
```

- [ ] **Step 2: Add A1 test packs**

```gdscript
# in get_test_packs()
{
	"pack_id": "pack_a1_enemy_melee",
	"battle_id": "battle_test_enemy_melee",
	"hero_id": "hero_angel",
	"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
	"strategy_ids": []
},
{
	"pack_id": "pack_a1_enemy_ranged",
	"battle_id": "battle_test_enemy_ranged",
	"hero_id": "hero_angel",
	"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
	"strategy_ids": []
},
{
	"pack_id": "pack_a1_enemy_mixed",
	"battle_id": "battle_test_enemy_mixed",
	"hero_id": "hero_angel",
	"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
	"strategy_ids": []
},
{
	"pack_id": "pack_a1_enemy_elite",
	"battle_id": "battle_test_enemy_elite",
	"hero_id": "hero_angel",
	"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
	"strategy_ids": []
}
```

- [ ] **Step 3: Extend content consistency battle list**

```gdscript
var battle_ids := [
	"battle_void_gate_alpha",
	"battle_void_gate_beta",
	"battle_void_gate_test_baseline",
	"battle_test_enemy_melee",
	"battle_test_enemy_ranged",
	"battle_test_enemy_mixed",
	"battle_test_enemy_elite"
]
```

- [ ] **Step 4: Run matrix and consistency tests to confirm GREEN**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_melee_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_ranged_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_mixed_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_elite_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/content_consistency_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add autoload/battle_content.gd tests/content_consistency_test.gd tests/runtime_enemy_matrix_melee_test.gd tests/runtime_enemy_matrix_ranged_test.gd tests/runtime_enemy_matrix_mixed_test.gd tests/runtime_enemy_matrix_elite_test.gd
git commit -m "feat: add phase A1 enemy matrix battles and runtime tests"
```

---

### Task 3: Expose A1 Presets in Preparation UI

**Files:**
- Modify: `scripts/prep/preparation_screen.gd`
- Modify: `tests/preparation_test_mode_preset_test.gd`

- [ ] **Step 1: Add preset constants**

```gdscript
const PRESET_A1_ENEMY_MELEE := "preset_a1_enemy_melee"
const PRESET_A1_ENEMY_RANGED := "preset_a1_enemy_ranged"
const PRESET_A1_ENEMY_MIXED := "preset_a1_enemy_mixed"
const PRESET_A1_ENEMY_ELITE := "preset_a1_enemy_elite"
```

- [ ] **Step 2: Add options into preset dropdown**

```gdscript
_add_test_preset_option(5, "测试预设：A1 多敌人（全近战）", PRESET_A1_ENEMY_MELEE)
_add_test_preset_option(6, "测试预设：A1 多敌人（全远程）", PRESET_A1_ENEMY_RANGED)
_add_test_preset_option(7, "测试预设：A1 多敌人（近远混合）", PRESET_A1_ENEMY_MIXED)
_add_test_preset_option(8, "测试预设：A1 多敌人（精英主导）", PRESET_A1_ENEMY_ELITE)
```

- [ ] **Step 3: Wire preset apply branches**

```gdscript
PRESET_A1_ENEMY_MELEE:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": _ally_ids_for_count(2),
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_melee"
	}
PRESET_A1_ENEMY_RANGED:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": _ally_ids_for_count(2),
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_ranged"
	}
PRESET_A1_ENEMY_MIXED:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": _ally_ids_for_count(2),
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_mixed"
	}
PRESET_A1_ENEMY_ELITE:
	_current_selection = {
		"hero_id": "hero_angel",
		"ally_ids": _ally_ids_for_count(2),
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_elite"
	}
```

- [ ] **Step 4: Extend preset UI test assertions**

```gdscript
# tests/preparation_test_mode_preset_test.gd
if _find_metadata_index(preset_select, "preset_a1_enemy_melee") < 0:
	_failures.append("expected preset_a1_enemy_melee")
if _find_metadata_index(preset_select, "preset_a1_enemy_ranged") < 0:
	_failures.append("expected preset_a1_enemy_ranged")
if _find_metadata_index(preset_select, "preset_a1_enemy_mixed") < 0:
	_failures.append("expected preset_a1_enemy_mixed")
if _find_metadata_index(preset_select, "preset_a1_enemy_elite") < 0:
	_failures.append("expected preset_a1_enemy_elite")

var a1_index := _find_metadata_index(preset_select, "preset_a1_enemy_elite")
if a1_index >= 0:
	preset_select.select(a1_index)
	preset_select.item_selected.emit(a1_index)
	apply_preset_button.pressed.emit()
	await process_frame
	var current_selection: Dictionary = screen.call("get_current_selection")
	if str(current_selection.get("battle_id", "")) != "battle_test_enemy_elite":
		_failures.append("A1 elite preset should map to battle_test_enemy_elite")
```

- [ ] **Step 5: Run prep tests and commit**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_controls_smoke_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_test_mode_preset_test.gd`

Expected: PASS.

```bash
git add scripts/prep/preparation_screen.gd tests/preparation_test_mode_preset_test.gd
git commit -m "feat: expose phase A1 enemy matrix presets in preparation"
```

---

### Task 4: Full A1 Regression Slice and Handoff Sync

**Files:**
- Modify: `docs/HANDOFF.md`

- [ ] **Step 1: Run A1 verification slice**

Run:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_melee_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_ranged_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_mixed_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_matrix_elite_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/preparation_test_mode_preset_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/content_consistency_test.gd`
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_event_unresolved_summon_spawn_test.gd`

Expected: all PASS.

- [ ] **Step 2: Update handoff section**

```markdown
## 本次改动（2026-03-31，Phase A1 多敌人关卡矩阵）
- 新增 4 类敌方矩阵关卡：全近战/全远程/近远混合/精英主导
- 准备页新增 A1 四个测试预设入口并可一键应用
- 新增 runtime 组成测试：runtime_enemy_matrix_{melee,ranged,mixed,elite}
- A1 回归切片通过（含 content consistency 与既有事件召唤回归）
```

- [ ] **Step 3: Commit docs**

```bash
git add docs/HANDOFF.md
git commit -m "docs: record phase A1 enemy matrix rollout"
```

---

## Self-Review

### Spec coverage check
- 四类敌方关卡矩阵：Task 2
- 准备页 A1 可见预设：Task 3
- runtime 与 UI 断言：Task 1 + Task 3 + Task 4
- Handoff 进度同步：Task 4

### Placeholder scan
- 无 TBD/TODO/implement later。
- 每个代码步骤给出具体片段与命令。

### Type consistency
- 预设 id 命名统一 `preset_a1_enemy_*`。
- battle id 命名统一 `battle_test_enemy_*`。
- 测试文件命名统一 `runtime_enemy_matrix_*_test.gd`。
