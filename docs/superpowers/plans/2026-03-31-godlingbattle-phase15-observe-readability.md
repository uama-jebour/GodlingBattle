# GodlingBattle Phase 15 Observe Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a readable Phase15 Observe experience at 1920x1080 with non-overlapping battlefield tokens, death-linger-then-remove lifecycle, and clearer right-side roster/log sections.

**Architecture:** Keep runtime contracts unchanged and implement Phase15 in Observe presentation/runtime glue. Upgrade the battlefield layout solver to stable side-slot mapping, add deterministic death lifecycle reconstruction for seek/jump, and split battle-log rendering into key-event and regular-detail sections while preserving current `get_*` compatibility methods.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` UI tree, headless tests (`tests/*.gd`), shell-based regression runner

---

## File Structure

Core files in this phase:

- `scripts/observe/battlefield_layout_solver.gd`: switch to side-slot layout output with bounds-safe clamping
- `scripts/observe/observe_screen.gd`: death lifecycle state machine, seek/jump rebuild, roster/log section rendering, readability font constants
- `scenes/observe/observe_screen.tscn`: panel typography and section node wiring for readability baseline
- `tests/observe_battlefield_non_overlap_test.gd`: expand dense-side coverage for slot layout
- `tests/token_view_death_marker_test.gd`: keep marker visibility contract
- `tests/observe_roster_log_panel_test.gd`: assert right-panel two-section output and alive-only roster
- `tests/observe_readability_font_size_test.gd`: enforce 1920x1080 readability thresholds
- `tests/observe_death_linger_removal_test.gd` (new): assert `alive -> linger -> removed` and seek/jump consistency

## Task 1: Lock Phase15 Readability Contract First (RED -> GREEN)

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_readability_font_size_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`

- [ ] **Step 1: Raise readability test thresholds (RED)**

```gdscript
# tests/observe_readability_font_size_test.gd (replace threshold assertion block in _run)
var targets := {
	"LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldTitle": 24,
	"LayoutRoot/LeftColumn/StrategyPanel/StrategyTitle": 24,
	"LayoutRoot/RightColumn/AliveRosterPanel/RosterTitle": 24,
	"LayoutRoot/RightColumn/BattleLogPanel/BattleLogTitle": 24
}
for path in targets.keys():
	var label := screen.get_node_or_null(path) as Label
	if label == null:
		_failures.append("missing label: %s" % path)
		continue
	var minimum_size := int(targets[path])
	var font_size := int(label.get_theme_font_size("font_size"))
	if font_size < minimum_size:
		_failures.append("%s font too small: %d" % [path, font_size])

var hud_targets := {
	"HudRoot/TickLabel": 44,
	"HudRoot/EventLabel": 30,
	"HudRoot/StrategyCastLabel": 30
}
for path in hud_targets.keys():
	var label := screen.get_node_or_null(path) as Label
	if label == null:
		_failures.append("missing hud label: %s" % path)
		continue
	var minimum_size := int(hud_targets[path])
	var font_size := int(label.get_theme_font_size("font_size"))
	if font_size < minimum_size:
		_failures.append("%s font too small: %d" % [path, font_size])
```

- [ ] **Step 2: Run readability test to confirm failure**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_readability_font_size_test.gd`

Expected: FAIL with at least one "font too small" assertion.

- [ ] **Step 3: Apply minimum-readable font constants in Observe UI**

```gdscript
# scripts/observe/observe_screen.gd (add near top constants)
const FONT_SIZE_PANEL_TITLE := 24
const FONT_SIZE_PANEL_BODY := 20
const FONT_SIZE_HUD_TICK := 44
const FONT_SIZE_HUD_EVENT := 30
```

```gdscript
# scripts/observe/observe_screen.gd (inside _ensure_hud)
_tick_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_TICK)
_event_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_EVENT)
_strategy_cast_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_EVENT)
```

```gdscript
# scripts/observe/observe_screen.gd (inside _build_roster_column)
heading.add_theme_font_size_override("font_size", FONT_SIZE_PANEL_TITLE)
body.add_theme_font_size_override("font_size", FONT_SIZE_PANEL_BODY)
```

```gdscript
# scripts/observe/observe_screen.gd (inside _ensure_battle_log_panel)
_battle_log_text_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_PANEL_BODY)
```

```tscn
[node name="BattlefieldTitle" type="Label" parent="LayoutRoot/LeftColumn/BattlefieldPanel"]
layout_mode = 2
text = "战场视图"
theme_override_font_sizes/font_size = 24

[node name="StrategyTitle" type="Label" parent="LayoutRoot/LeftColumn/StrategyPanel"]
layout_mode = 2
text = "战术策略"
theme_override_font_sizes/font_size = 24

[node name="RosterTitle" type="Label" parent="LayoutRoot/RightColumn/AliveRosterPanel"]
layout_mode = 2
text = "存活名册"
theme_override_font_sizes/font_size = 24

[node name="BattleLogTitle" type="Label" parent="LayoutRoot/RightColumn/BattleLogPanel"]
layout_mode = 2
text = "战斗日志"
theme_override_font_sizes/font_size = 24
```

- [ ] **Step 4: Re-run readability test (GREEN)**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_readability_font_size_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit readability baseline**

```bash
git add tests/observe_readability_font_size_test.gd scenes/observe/observe_screen.tscn scripts/observe/observe_screen.gd
git commit -m "feat: raise observe readability baseline for phase15"
```

## Task 2: Implement Slot-Based Battlefield Layout (RED -> GREEN)

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_battlefield_non_overlap_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/battlefield_layout_solver.gd`

- [ ] **Step 1: Add dense-side non-overlap test cases (RED)**

```gdscript
# tests/observe_battlefield_non_overlap_test.gd (append in _run)
var dense_rows := [
	{"entity_id":"ally_0","side":"ally","position":Vector2(120,180)},
	{"entity_id":"ally_1","side":"ally","position":Vector2(124,182)},
	{"entity_id":"ally_2","side":"ally","position":Vector2(128,184)},
	{"entity_id":"ally_3","side":"ally","position":Vector2(132,186)},
	{"entity_id":"enemy_0","side":"enemy","position":Vector2(480,180)},
	{"entity_id":"enemy_1","side":"enemy","position":Vector2(484,182)},
	{"entity_id":"enemy_2","side":"enemy","position":Vector2(488,184)},
	{"entity_id":"enemy_3","side":"enemy","position":Vector2(492,186)}
]
var dense_resolved: Array = solver.resolve(dense_rows, Rect2(0, 0, 640, 360))
_assert_side_non_overlap(dense_resolved, "ally", "dense ally slots should not overlap")
_assert_side_non_overlap(dense_resolved, "enemy", "dense enemy slots should not overlap")
```

```gdscript
# tests/observe_battlefield_non_overlap_test.gd (add helper)
func _assert_side_non_overlap(rows: Array, side: String, message: String) -> void:
	var rects: Array[Rect2] = []
	for row in rows:
		var row_side := str(row.get("side", ""))
		var group_side := "enemy" if row_side == "enemy" else "ally"
		if group_side != side:
			continue
		rects.append(Rect2(row.get("position", Vector2.ZERO), TOKEN_SIZE))
	for i in range(rects.size()):
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				_failures.append("%s (a=%s, b=%s)" % [message, rects[i], rects[j]])
				return
```

- [ ] **Step 2: Run non-overlap test to confirm failure**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battlefield_non_overlap_test.gd`

Expected: FAIL in dense overlap assertions.

- [ ] **Step 3: Replace solver with side-slot mapping implementation**

```gdscript
# scripts/observe/battlefield_layout_solver.gd (replace file)
extends RefCounted

const TOKEN_SIZE := Vector2(96, 112)
const SLOT_GAP_Y := 10.0
const SLOT_MARGIN_X := 24.0
const SLOT_MARGIN_Y := 16.0
const FALLBACK_BOUNDS := Rect2(0, 0, 640, 360)


func resolve(rows: Array, bounds: Rect2) -> Array:
	var resolved: Array = rows.duplicate(true)
	var layout_bounds := _normalized_bounds(bounds)
	var ally_indices: Array[int] = []
	var enemy_indices: Array[int] = []
	for index in range(resolved.size()):
		var row := resolved[index]
		if row is not Dictionary:
			continue
		if _group_side(str(row.get("side", ""))) == "enemy":
			enemy_indices.append(index)
		else:
			ally_indices.append(index)
	_layout_side(resolved, ally_indices, layout_bounds, false)
	_layout_side(resolved, enemy_indices, layout_bounds, true)
	return resolved


func _layout_side(resolved: Array, indices: Array[int], bounds: Rect2, right_side: bool) -> void:
	if indices.is_empty():
		return
	indices.sort_custom(func(a: int, b: int) -> bool:
		return _sort_score(resolved[a]) < _sort_score(resolved[b])
	)
	var y_values := _slot_y_values(indices.size(), bounds)
	var x := _slot_x(bounds, right_side)
	for slot_index in range(indices.size()):
		var row_index := indices[slot_index]
		var row: Dictionary = resolved[row_index]
		row["position"] = Vector2(x, y_values[slot_index])
		resolved[row_index] = row


func _slot_y_values(count: int, bounds: Rect2) -> Array[float]:
	var safe := _footprint_bounds(bounds)
	if count <= 1:
		return [safe.position.y + safe.size.y * 0.5]
	var total_height := safe.size.y
	var spacing := minf(TOKEN_SIZE.y + SLOT_GAP_Y, total_height / float(count - 1))
	var used_height := spacing * float(count - 1)
	var first_y := safe.position.y + (total_height - used_height) * 0.5
	var ys: Array[float] = []
	for i in range(count):
		ys.append(first_y + float(i) * spacing)
	return ys


func _slot_x(bounds: Rect2, right_side: bool) -> float:
	var safe := _footprint_bounds(bounds)
	if right_side:
		return safe.end.x - SLOT_MARGIN_X
	return safe.position.x + SLOT_MARGIN_X


func _group_side(side: String) -> String:
	return "enemy" if side == "enemy" else "ally"


func _sort_score(row: Dictionary) -> float:
	var pos := _row_position(row)
	return pos.y * 10000.0 + pos.x


func _row_position(row: Dictionary) -> Vector2:
	var raw = row.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _normalized_bounds(bounds: Rect2) -> Rect2:
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds
	return FALLBACK_BOUNDS


func _footprint_bounds(bounds: Rect2) -> Rect2:
	return Rect2(
		bounds.position + Vector2(SLOT_MARGIN_X, SLOT_MARGIN_Y),
		Vector2(
			maxf(bounds.size.x - TOKEN_SIZE.x - SLOT_MARGIN_X * 2.0, 0.0),
			maxf(bounds.size.y - TOKEN_SIZE.y - SLOT_MARGIN_Y * 2.0, 0.0)
		)
	)
```

- [ ] **Step 4: Run non-overlap test (GREEN)**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battlefield_non_overlap_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit slot layout solver**

```bash
git add tests/observe_battlefield_non_overlap_test.gd scripts/observe/battlefield_layout_solver.gd
git commit -m "feat: use side-slot battlefield layout for observe phase15"
```

## Task 3: Add Death Linger Then Remove Lifecycle (RED -> GREEN)

**Files:**
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_death_linger_removal_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`

- [ ] **Step 1: Create failing lifecycle regression test (RED)**

```gdscript
extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return

	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": [
			{"entity_id":"hero_angel_0","display_name":"英雄：天使","side":"hero","alive":true,"hp":100.0,"max_hp":100.0,"position":Vector2(140,180)}
		]},
		{"tick": 1, "entities": [
			{"entity_id":"hero_angel_0","display_name":"英雄：天使","side":"hero","alive":false,"hp":0.0,"max_hp":100.0,"position":Vector2(140,180)}
		]},
		{"tick": 20, "entities": [
			{"entity_id":"hero_angel_0","display_name":"英雄：天使","side":"hero","alive":false,"hp":0.0,"max_hp":100.0,"position":Vector2(140,180)}
		]}
	]
	session_state.last_battle_result = {"log_entries": [{"tick":1,"type":"hero_down","entity_id":"hero_angel_0"}]}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("_seek_to_frame"):
		_failures.append("missing _seek_to_frame")
	else:
		screen.call("_seek_to_frame", 1)
		var death_token := screen.call("get_token_view", "hero_angel_0")
		if death_token == null:
			_failures.append("token should exist during linger")
		screen.call("_seek_to_frame", 2)
		var removed_token := screen.call("get_token_view", "hero_angel_0")
		if removed_token != null:
			_failures.append("token should be removed after linger expiry")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for f in _failures:
		printerr(f)
	quit(1)
```

- [ ] **Step 2: Run lifecycle test to confirm failure**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_death_linger_removal_test.gd`

Expected: FAIL because dead tokens are currently removed immediately.

- [ ] **Step 3: Implement dead-token linger cache and rebuild logic**

```gdscript
# scripts/observe/observe_screen.gd (add constants/fields)
const DEAD_TOKEN_LINGER_TICKS := 8
var _linger_cache_by_entity: Dictionary = {}
```

```gdscript
# scripts/observe/observe_screen.gd (add helper)
func _rebuild_linger_cache_to_frame(frame_index: int) -> void:
	_linger_cache_by_entity.clear()
	if frame_index < 0 or frame_index >= _timeline.size():
		return
	for i in range(frame_index + 1):
		var frame: Dictionary = _timeline[i]
		var tick := int(frame.get("tick", 0))
		for entity in frame.get("entities", []):
			var entity_id := str(entity.get("entity_id", ""))
			if entity_id.is_empty():
				continue
			if bool(entity.get("alive", false)):
				_linger_cache_by_entity.erase(entity_id)
				continue
			if not _linger_cache_by_entity.has(entity_id):
				_linger_cache_by_entity[entity_id] = {
					"until_tick": tick + DEAD_TOKEN_LINGER_TICKS,
					"snapshot": entity.duplicate(true)
				}
```

```gdscript
# scripts/observe/observe_screen.gd (add helper)
func _effective_entities_for_tick(tick: int, entities: Array) -> Array:
	var rows: Array = []
	var alive_ids: Dictionary = {}
	for entity in entities:
		var entity_id := str(entity.get("entity_id", ""))
		if entity_id.is_empty():
			continue
		if bool(entity.get("alive", false)):
			alive_ids[entity_id] = true
			rows.append(entity)
			continue
		var linger := _linger_cache_by_entity.get(entity_id, {})
		if linger is Dictionary and tick <= int(linger.get("until_tick", -1)):
			rows.append(entity)
	for entity_id in _linger_cache_by_entity.keys():
		if alive_ids.has(entity_id):
			continue
		var linger_row: Dictionary = _linger_cache_by_entity[entity_id]
		if tick <= int(linger_row.get("until_tick", -1)):
			rows.append((linger_row.get("snapshot", {}) as Dictionary).duplicate(true))
	return rows
```

```gdscript
# scripts/observe/observe_screen.gd (apply in seek and frame apply)
func _seek_to_frame(frame_index: int) -> void:
	if _timeline.is_empty():
		return
	var target_index := clampi(frame_index, 0, _timeline.size() - 1)
	var frame: Dictionary = _timeline[target_index]
	_current_frame_index = target_index
	_rebuild_linger_cache_to_frame(target_index)
	apply_timeline_frame(frame)
	_frame_index = target_index + 1
	_playback_accumulator = 0.0
	_is_playing = _frame_index < _timeline.size()
	set_process(_is_playing)
	_refresh_progress_slider()
	_refresh_playback_controls()

func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = _effective_entities_for_tick(_current_tick, frame.get("entities", []).duplicate(true))
	_prev_hp_by_entity = _hp_lookup_for_frame_index(_current_frame_index - 1)
	var snapshot := build_token_snapshot()
	sync_token_views(snapshot)
	_ensure_map()
	_battle_map.call("set_snapshot", snapshot)
	update_hud_for_tick(_current_tick, _event_rows)
```

- [ ] **Step 4: Re-run lifecycle and existing death-marker test (GREEN)**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_death_linger_removal_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_death_marker_test.gd`

Expected: both PASS.

- [ ] **Step 5: Commit death lifecycle behavior**

```bash
git add tests/observe_death_linger_removal_test.gd scripts/observe/observe_screen.gd tests/token_view_death_marker_test.gd
git commit -m "feat: add death linger then remove lifecycle in observe"
```

## Task 4: Split Right Panel Into Key Events + Regular Logs (RED -> GREEN)

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_roster_log_panel_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/battle_report_formatter.gd`

- [ ] **Step 1: Extend right-panel test to require two log sections (RED)**

```gdscript
# tests/observe_roster_log_panel_test.gd (append assertions)
if log_text.find("关键事件") == -1:
	_failures.append("log should include key-event section")
if log_text.find("普通日志") == -1:
	_failures.append("log should include regular-log section")
```

- [ ] **Step 2: Run right-panel test to confirm failure**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_roster_log_panel_test.gd`

Expected: FAIL for missing section headers.

- [ ] **Step 3: Implement key-event extraction and section formatting**

```gdscript
# scripts/observe/battle_report_formatter.gd (add helper)
func build_key_event_lines(rows: Array, current_tick: int, limit: int = 8) -> Array[String]:
	var matched: Array[String] = []
	for row in rows:
		var tick := int(row.get("tick", -1))
		if tick < 0 or tick > current_tick:
			continue
		var t := str(row.get("type", ""))
		if t in ["hero_down", "ally_down", "enemy_down", "event_unresolved_effect"]:
			matched.append(_build_detail_line(row, tick))
		elif t == "event_resolve" and not bool(row.get("responded", false)):
			matched.append(_build_detail_line(row, tick))
	if matched.is_empty():
		return ["暂无关键事件"]
	var safe_limit := maxi(1, limit)
	return matched.slice(maxi(0, matched.size() - safe_limit), matched.size())
```

```gdscript
# scripts/observe/observe_screen.gd (replace _build_battle_log_lines)
func _build_battle_log_lines(limit: int = 18) -> Array[String]:
	var key_lines := _battle_report_formatter.build_key_event_lines(_event_rows, _display_tick(), 8)
	var normal_lines := _battle_report_formatter.build_recent_detail(_event_rows, _display_tick(), "all", limit)
	var lines: Array[String] = ["关键事件"]
	for line in key_lines:
		lines.append("- %s" % String(line))
	lines.append("")
	lines.append("普通日志")
	for line in normal_lines:
		lines.append("- %s" % String(line))
	return lines
```

- [ ] **Step 4: Re-run right-panel test (GREEN)**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_roster_log_panel_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit right-panel section rendering**

```bash
git add tests/observe_roster_log_panel_test.gd scripts/observe/observe_screen.gd scripts/observe/battle_report_formatter.gd
git commit -m "feat: add key-event and regular-log sections in observe panel"
```

## Task 5: Full Observe Regression + Handoff Update

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [ ] **Step 1: Run targeted Observe regression suite**

Run:

`for t in $(rg --files tests -g 'observe_*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`

Expected: all Observe tests PASS.

- [ ] **Step 2: Run full regression gate**

Run:

`for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`

Expected: full suite PASS.

- [ ] **Step 3: Update handoff with Phase15 progress and verification results**

```markdown
## 本次改动（2026-03-31，Phase15 可读性增强，当前工作区）

- Observe 战场改为同侧槽位布局，消除 token 重叠
- 死亡单位改为短暂残影后消失，并兼容 seek/jump
- 右侧战报中心拆分“关键事件 + 普通日志”
- 1920x1080 字号可读性基线提升并新增守卫测试

验证结果（当前工作区）：
- `tests/observe_*.gd` 全通过
- `tests/*.gd` 全通过
```

- [ ] **Step 4: Commit verification + handoff update**

```bash
git add docs/HANDOFF.md
git commit -m "docs: record phase15 observe readability delivery and regression results"
```

## Self-Review Checklist (Must Run Before Execution)

1. Spec coverage:
- Non-overlap via slot layout: Task 2
- Death linger then remove + seek/jump consistency: Task 3
- Right-side sections + alive-only roster: Task 4
- 1920x1080 readability thresholds: Task 1
- Observe/full regressions and handoff: Task 5

2. Placeholder scan:
- No `TBD`/`TODO` placeholders remain.
- Every code-changing step includes concrete snippets.
- Every verification step includes exact command + expected result.

3. Type/API consistency:
- `resolve(rows, bounds)` signature unchanged for solver integration.
- Observe helper methods keep existing names (`get_alive_roster_text`, `get_battle_log_text`, etc.).
- Added formatter API name is consistent: `build_key_event_lines`.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-03-31-godlingbattle-phase15-observe-readability.md`.

Two execution options:

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints.

Note: Per AGENTS convention and your explicit requirement, if we choose Subagent-Driven, sub-agents will use single-pass acceptance (`实现 -> 基础验证 -> 集成`) and will not perform mandatory two-round code/quality reviews unless the change is high-risk.
