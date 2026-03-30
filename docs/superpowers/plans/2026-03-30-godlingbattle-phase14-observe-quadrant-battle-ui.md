# GodlingBattle Phase 14 Observe Quadrant Battle UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `Observe` into a four-quadrant combat UI that matches the approved V3 prototype: non-overlapping battlefield units, strategy cards with trigger/cooldown feedback, 25/75 right-side roster/log split, and readable typography with death markers.

**Architecture:** Keep runtime contracts stable and implement the feature mostly in `Observe` presentation. Add a battlefield layout solver for anti-overlap, extend `TokenView` visual-state flags for hit/effect/death markers, and render strategy/roster/log panels from existing timeline + battle report data. Preserve current playback and event-navigation behavior.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scene graph UI, headless regression tests (`tests/*.gd`)

---

## File Structure

Core files for this phase:

- `scenes/observe/observe_screen.tscn`: four-quadrant layout node tree
- `scripts/observe/observe_screen.gd`: orchestration (playback + snapshot + strategy/roster/log rendering)
- `scripts/observe/token_view.gd`: unit rendering and visual-state flags (`hit`, `affected`, `dead`)
- `scripts/observe/battlefield_layout_solver.gd` (new): anti-overlap layout pass for battlefield tokens
- `scripts/observe/battle_report_formatter.gd`: richer event text for log panel (including warning countdown text)
- `scripts/battle_runtime/battle_state.gd`: enemy fallback display name update to avoid generic `"敌方单位"`
- `scenes/observe/strategy_card_view.tscn` (new): reusable strategy card node
- `scripts/observe/strategy_card_view.gd` (new): strategy card state update (`triggered`, cooldown fill)

New/updated tests:

- `tests/observe_quadrant_layout_test.gd` (new): layout ratio and key-node existence
- `tests/observe_readability_font_size_test.gd` (new): minimum font-size guard for key UI text
- `tests/observe_battlefield_non_overlap_test.gd` (new): solver guarantees minimum spacing
- `tests/token_view_death_marker_test.gd` (new): death marker visibility + linger behavior
- `tests/observe_strategy_card_runtime_test.gd` (new): cooldown fill + trigger state
- `tests/observe_roster_log_panel_test.gd` (new): right-top alive roster and right-bottom log text coverage
- `tests/observe_ui_interaction_accessibility_test.gd` (modify): mouse passthrough still valid with new hierarchy
- `tests/observe_map_view_smoke_test.gd` (modify): layer order assertions adapted to new structure

## Task 1: Build Four-Quadrant Scene Skeleton And Readability Baseline

**Files:**
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_quadrant_layout_test.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_readability_font_size_test.gd`

- [ ] **Step 1: Write failing quadrant-layout test (RED)**

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
		"strategy_ids": ["strat_chill_wave", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	for path in [
		"LayoutRoot",
		"LayoutRoot/LeftColumn/BattlefieldPanel",
		"LayoutRoot/LeftColumn/StrategyPanel",
		"LayoutRoot/RightColumn/AliveRosterPanel",
		"LayoutRoot/RightColumn/BattleLogPanel"
	]:
		if screen.get_node_or_null(path) == null:
			_failures.append("missing node: %s" % path)

	if not screen.has_method("get_layout_ratio_snapshot"):
		_failures.append("missing get_layout_ratio_snapshot")
	else:
		var ratio: Dictionary = screen.call("get_layout_ratio_snapshot")
		if absf(float(ratio.get("left", 0.0)) - 0.68) > 0.02:
			_failures.append("left ratio should be ~0.68")
		if absf(float(ratio.get("right_top", 0.0)) - 0.25) > 0.03:
			_failures.append("right top ratio should be ~0.25")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_quadrant_layout_test.gd`

Expected: FAIL with missing `LayoutRoot` or missing `get_layout_ratio_snapshot`.

- [ ] **Step 3: Write failing readability-font test (RED)**

```gdscript
extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var targets := {
		"LayoutRoot/LeftColumn/StrategyPanel/StrategyTitle": 15,
		"LayoutRoot/RightColumn/AliveRosterPanel/RosterTitle": 15,
		"LayoutRoot/RightColumn/BattleLogPanel/BattleLogTitle": 15
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

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 4: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_readability_font_size_test.gd`

Expected: FAIL because new title labels and font overrides do not exist yet.

- [ ] **Step 5: Implement quadrant scene tree + ratio API + readable fonts**

```gdscript
# scripts/observe/observe_screen.gd (additions)
@onready var _layout_root: Control = $LayoutRoot
@onready var _left_column: Control = $LayoutRoot/LeftColumn
@onready var _right_column: Control = $LayoutRoot/RightColumn
@onready var _battlefield_panel: Control = $LayoutRoot/LeftColumn/BattlefieldPanel
@onready var _strategy_panel: Control = $LayoutRoot/LeftColumn/StrategyPanel
@onready var _alive_roster_panel: Control = $LayoutRoot/RightColumn/AliveRosterPanel
@onready var _battle_log_panel: Control = $LayoutRoot/RightColumn/BattleLogPanel

func get_layout_ratio_snapshot() -> Dictionary:
	var root_size := _layout_root.size
	if root_size.x <= 0.0 or root_size.y <= 0.0:
		return {"left": 0.0, "right_top": 0.0}
	var left_ratio := _left_column.size.x / root_size.x
	var right_top_ratio := _alive_roster_panel.size.y / maxf(_right_column.size.y, 1.0)
	return {
		"left": left_ratio,
		"right_top": right_top_ratio
	}
```

```tscn
[node name="LayoutRoot" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = 120.0
offset_right = -16.0
offset_bottom = -16.0
theme_override_constants/separation = 10

[node name="LeftColumn" type="VBoxContainer" parent="LayoutRoot"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 68.0
theme_override_constants/separation = 10

[node name="RightColumn" type="VBoxContainer" parent="LayoutRoot"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 32.0
theme_override_constants/separation = 10
```

- [ ] **Step 6: Run new tests and smoke checks**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_quadrant_layout_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_readability_font_size_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_map_view_smoke_test.gd`

Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add scenes/observe/observe_screen.tscn scripts/observe/observe_screen.gd tests/observe_quadrant_layout_test.gd tests/observe_readability_font_size_test.gd tests/observe_map_view_smoke_test.gd
git commit -m "feat: build quadrant observe layout with readability baseline"
```

## Task 2: Add Battlefield Non-Overlap Solver And Enemy Name Fallback Guard

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/battlefield_layout_solver.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_state.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_battlefield_non_overlap_test.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/runtime_enemy_name_fallback_test.gd`

- [ ] **Step 1: Write failing non-overlap solver test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var solver_script: GDScript = load("res://scripts/observe/battlefield_layout_solver.gd")
	if solver_script == null:
		_failures.append("missing battlefield_layout_solver.gd")
		_finish()
		return
	var solver: RefCounted = solver_script.new()
	var rows: Array = [
		{"entity_id": "ally_0", "side": "ally", "position": Vector2(300, 280)},
		{"entity_id": "ally_1", "side": "ally", "position": Vector2(300, 280)},
		{"entity_id": "enemy_0", "side": "enemy", "position": Vector2(700, 280)},
		{"entity_id": "enemy_1", "side": "enemy", "position": Vector2(700, 280)}
	]
	var solved: Array = solver.call("resolve", rows, Rect2(Vector2(0, 0), Vector2(1280, 720)))
	if solved.size() != 4:
		_failures.append("resolve should keep all rows")
	else:
		var p0 := solved[0].get("position", Vector2.ZERO)
		var p1 := solved[1].get("position", Vector2.ZERO)
		var p2 := solved[2].get("position", Vector2.ZERO)
		var p3 := solved[3].get("position", Vector2.ZERO)
		if p0.distance_to(p1) < 90.0:
			_failures.append("ally tokens should keep min spacing")
		if p2.distance_to(p3) < 90.0:
			_failures.append("enemy tokens should keep min spacing")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battlefield_non_overlap_test.gd`

Expected: FAIL with `missing battlefield_layout_solver.gd`.

- [ ] **Step 3: Write failing enemy-fallback-name test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state_builder: RefCounted = load("res://scripts/battle_runtime/battle_state.gd").new()
	var fallback: Dictionary = state_builder.call("_fallback_enemy_def", "enemy_unknown")
	if str(fallback.get("display_name", "")) == "敌方单位":
		_failures.append("enemy display_name should not be generic '敌方单位'")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 4: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_name_fallback_test.gd`

Expected: FAIL if fallback name remains generic.

- [ ] **Step 5: Implement layout solver and integrate into snapshot pipeline**

```gdscript
# scripts/observe/battlefield_layout_solver.gd
extends RefCounted

const MIN_SPACING := 96.0

func resolve(rows: Array, viewport_rect: Rect2) -> Array:
	var resolved: Array = []
	var ally_anchor := viewport_rect.position + Vector2(viewport_rect.size.x * 0.28, viewport_rect.size.y * 0.5)
	var enemy_anchor := viewport_rect.position + Vector2(viewport_rect.size.x * 0.72, viewport_rect.size.y * 0.5)
	var ally_index := 0
	var enemy_index := 0
	for row in rows:
		var patched := row.duplicate(true)
		var side := str(row.get("side", ""))
		var idx := ally_index
		var anchor := ally_anchor
		if side == "enemy":
			idx = enemy_index
			anchor = enemy_anchor
			enemy_index += 1
		else:
			ally_index += 1
		var lane := float(idx % 3) - 1.0
		var depth := float(idx / 3)
		patched["position"] = anchor + Vector2(depth * 56.0, lane * MIN_SPACING)
		resolved.append(patched)
	return resolved
```

```gdscript
# scripts/observe/observe_screen.gd (integration)
const BATTLEFIELD_LAYOUT_SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")
var _layout_solver := BATTLEFIELD_LAYOUT_SOLVER.new()

func build_token_snapshot() -> Array:
	var rows: Array = []
	for entity in _current_entities:
		rows.append({
			"entity_id": str(entity.get("entity_id", "")),
			"display_name": _unit_display_name_from_entity_id(str(entity.get("entity_id", ""))),
			"side": str(entity.get("side", "")),
			"hp_ratio": _hp_ratio(entity),
			"alive": bool(entity.get("alive", false)),
			"position": _entity_position(entity)
		})
	return _layout_solver.resolve(rows, Rect2(Vector2.ZERO, size))
```

- [ ] **Step 6: Update enemy fallback display name**

```gdscript
# scripts/battle_runtime/battle_state.gd
func _fallback_enemy_def(enemy_id: String) -> Dictionary:
	return {
		"unit_id": enemy_id,
		"display_name": "未知敌方单位",
		"max_hp": 30.0,
		"attack_power": 3.0,
		"attack_speed": 1.0,
		"attack_range": 1.0,
		"move_speed": 8.0
	}
```

- [ ] **Step 7: Run tests**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battlefield_non_overlap_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_enemy_name_fallback_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_token_render_test.gd`

Expected: all PASS.

- [ ] **Step 8: Commit**

```bash
git add scripts/observe/battlefield_layout_solver.gd scripts/observe/observe_screen.gd scripts/battle_runtime/battle_state.gd tests/observe_battlefield_non_overlap_test.gd tests/runtime_enemy_name_fallback_test.gd tests/observe_token_render_test.gd
git commit -m "feat: add battlefield non-overlap solver and enemy fallback name guard"
```

## Task 3: Add Token Hit/Effect/Death Visual States (Including Death Marker)

**Files:**
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/token_view.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/token_view.tscn`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/token_view_death_marker_test.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/token_view_effect_state_test.gd`

- [ ] **Step 1: Write failing death-marker test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	if not token.has_method("set_visual_flags"):
		_failures.append("missing set_visual_flags")
		_finish(token)
		return
	token.call("set_visual_flags", {"is_dead": true, "show_death_marker_until_tick": 24})
	if not bool(token.get("is_dead")):
		_failures.append("token should hold is_dead=true")
	if not token.has_method("is_death_marker_visible"):
		_failures.append("missing is_death_marker_visible")
	else:
		if not bool(token.call("is_death_marker_visible", 12)):
			_failures.append("death marker should be visible before expiry")
		if bool(token.call("is_death_marker_visible", 30)):
			_failures.append("death marker should hide after expiry")
	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_death_marker_test.gd`

Expected: FAIL with missing `set_visual_flags` or `is_death_marker_visible`.

- [ ] **Step 3: Write failing hit/effect-state test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	token.call("set_visual_flags", {"is_hit": true, "is_affected": true, "is_dead": false})
	if not bool(token.get("is_hit")):
		_failures.append("is_hit should be true")
	if not bool(token.get("is_affected")):
		_failures.append("is_affected should be true")
	if bool(token.get("is_dead")):
		_failures.append("is_dead should be false")
	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 4: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_effect_state_test.gd`

Expected: FAIL because flags do not exist.

- [ ] **Step 5: Implement token visual flags + death-marker drawing**

```gdscript
# scripts/observe/token_view.gd
var is_hit := false
var is_affected := false
var is_dead := false
var show_death_marker_until_tick := -1

func set_visual_flags(flags: Dictionary) -> void:
	is_hit = bool(flags.get("is_hit", false))
	is_affected = bool(flags.get("is_affected", false))
	is_dead = bool(flags.get("is_dead", false))
	show_death_marker_until_tick = int(flags.get("show_death_marker_until_tick", -1))
	queue_redraw()

func is_death_marker_visible(current_tick: int) -> bool:
	return is_dead and current_tick <= show_death_marker_until_tick

func _draw() -> void:
	# existing body + hp drawing...
	if is_hit:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.2, 0.2, 0.22), true)
	if is_affected:
		draw_arc(size * 0.5, 22.0, 0.0, TAU, 24, Color(0.55, 0.86, 1.0, 0.9), 2.0)
	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(8, 38), "已阵亡", HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 14, Color(1.0, 0.82, 0.82))
```

```gdscript
# scripts/observe/observe_screen.gd
const DEATH_MARKER_LINGER_TICKS := 12
var _prev_hp_by_entity: Dictionary = {}
var _death_marker_until_tick: Dictionary = {}

func _build_visual_flags(entity: Dictionary) -> Dictionary:
	var entity_id := str(entity.get("entity_id", ""))
	var hp_now := float(entity.get("hp", 0.0))
	var hp_prev := float(_prev_hp_by_entity.get(entity_id, hp_now))
	var is_hit := hp_now < hp_prev
	var is_dead := not bool(entity.get("alive", false))
	if is_dead and not _death_marker_until_tick.has(entity_id):
		_death_marker_until_tick[entity_id] = _current_tick + DEATH_MARKER_LINGER_TICKS
	_prev_hp_by_entity[entity_id] = hp_now
	return {
		"is_hit": is_hit,
		"is_affected": _has_tick_effect(entity_id, _current_tick),
		"is_dead": is_dead,
		"show_death_marker_until_tick": int(_death_marker_until_tick.get(entity_id, -1))
	}

func _has_tick_effect(entity_id: String, tick: int) -> bool:
	for row in _event_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if str(row.get("type", "")) == "strategy_cast":
			return true
		if str(row.get("entity_id", "")) == entity_id and str(row.get("type", "")) in ["ally_down", "hero_down", "enemy_down"]:
			return true
	return false
```

- [ ] **Step 6: Run token visual tests**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_death_marker_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_effect_state_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_visual_state_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/token_view_low_hp_color_test.gd`

Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add scripts/observe/token_view.gd scenes/observe/token_view.tscn scripts/observe/observe_screen.gd tests/token_view_death_marker_test.gd tests/token_view_effect_state_test.gd tests/token_view_visual_state_test.gd tests/token_view_low_hp_color_test.gd
git commit -m "feat: add token hit effect and death marker visual states"
```

## Task 4: Implement Strategy Cards, Alive Roster, And Rich Battle Log Panel

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/strategy_card_view.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/strategy_card_view.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/battle_report_formatter.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_strategy_card_runtime_test.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_roster_log_panel_test.gd`

- [ ] **Step 1: Write failing strategy-card runtime test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card: Control = load("res://scripts/observe/strategy_card_view.gd").new()
	if not card.has_method("apply_state"):
		_failures.append("missing apply_state")
		_finish(card)
		return
	card.call("apply_state", {
		"name": "寒潮冲击",
		"cooldown_ratio": 0.50,
		"cooldown_remaining_seconds": 4.0,
		"cooldown_total_seconds": 8.0,
		"triggered": true
	})
	if not bool(card.get("is_triggered")):
		_failures.append("card should be triggered")
	if absf(float(card.get("cooldown_ratio")) - 0.5) > 0.001:
		_failures.append("cooldown_ratio should be 0.5")
	_finish(card)


func _finish(card: Control) -> void:
	card.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_strategy_card_runtime_test.gd`

Expected: FAIL with missing `strategy_card_view.gd`.

- [ ] **Step 3: Write failing roster-log integration test (RED)**

```gdscript
extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{
		"tick": 0,
		"entities": [
			{"entity_id": "hero_angel_0", "display_name": "英雄：天使", "side": "hero", "alive": true, "hp": 80.0, "max_hp": 100.0, "position": Vector2(200, 200)},
			{"entity_id": "enemy_hunter_fiend_4", "display_name": "追猎魔", "side": "enemy", "alive": true, "hp": 30.0, "max_hp": 30.0, "position": Vector2(600, 240)}
		]
	}]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 0, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"},
			{"tick": 0, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 0, "type": "enemy_down", "entity_id": "enemy_hunter_fiend_4"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("get_alive_roster_text"):
		_failures.append("missing get_alive_roster_text")
	else:
		var roster_text := String(screen.call("get_alive_roster_text"))
		if roster_text.find("英雄：天使") == -1:
			_failures.append("roster should contain ally unit name")
		if roster_text.find("追猎魔") == -1:
			_failures.append("roster should contain enemy unit name")

	if not screen.has_method("get_battle_log_text"):
		_failures.append("missing get_battle_log_text")
	else:
		var log_text := String(screen.call("get_battle_log_text"))
		if log_text.find("5秒后") == -1:
			_failures.append("log should include warning countdown text")
		if log_text.find("施放") == -1:
			_failures.append("log should include strategy cast text")
		if log_text.find("倒下") == -1:
			_failures.append("log should include death text")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 4: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_roster_log_panel_test.gd`

Expected: FAIL with missing `get_alive_roster_text` and `get_battle_log_text`.

- [ ] **Step 5: Implement strategy card component + runtime update pipeline**

```gdscript
# scripts/observe/strategy_card_view.gd
extends Control

var strategy_name := ""
var cooldown_ratio := 0.0
var is_triggered := false

@onready var _name_label: Label = $NameLabel
@onready var _cooldown_label: Label = $CooldownLabel
@onready var _cooldown_fill: ColorRect = $CooldownFill

func apply_state(state: Dictionary) -> void:
	strategy_name = str(state.get("name", "未知战技"))
	cooldown_ratio = clampf(float(state.get("cooldown_ratio", 0.0)), 0.0, 1.0)
	is_triggered = bool(state.get("triggered", false))
	var remaining := float(state.get("cooldown_remaining_seconds", 0.0))
	var total := maxf(float(state.get("cooldown_total_seconds", 0.0)), 0.01)
	_name_label.text = strategy_name
	_cooldown_label.text = "冷却 %.1fs / %.1fs" % [remaining, total]
	_cooldown_fill.anchor_top = 1.0 - cooldown_ratio
	modulate = Color(1, 1, 1, 1.0) if not is_triggered else Color(1.12, 1.12, 1.12, 1.0)
```

```gdscript
# scripts/observe/observe_screen.gd (strategy state)
func _build_strategy_card_states(tick: int) -> Array:
	var states: Array = []
	var tick_rate := 10.0
	for strategy_id in _session_state().battle_setup.get("strategy_ids", []):
		var strategy_name := _strategy_display_name(str(strategy_id))
		var cooldown_total := _strategy_cooldown_seconds(str(strategy_id))
		var last_cast_tick := _last_cast_tick_for_strategy(str(strategy_id), tick)
		var elapsed_since_cast := maxf(0.0, float(tick - last_cast_tick) / tick_rate)
		var remaining := 0.0
		if last_cast_tick >= 0 and cooldown_total > 0.0:
			remaining = maxf(0.0, cooldown_total - elapsed_since_cast)
		var ratio := 1.0
		if cooldown_total > 0.0:
			ratio = clampf(1.0 - (remaining / cooldown_total), 0.0, 1.0)
		states.append({
			"strategy_id": str(strategy_id),
			"name": strategy_name,
			"cooldown_total_seconds": cooldown_total,
			"cooldown_remaining_seconds": remaining,
			"cooldown_ratio": ratio,
			"triggered": _is_strategy_triggered_at_tick(str(strategy_id), tick)
		})
	return states

func _strategy_cooldown_seconds(strategy_id: String) -> float:
	var content := load("res://autoload/battle_content.gd").new()
	var strategy_def: Dictionary = content.get_strategy(strategy_id)
	content.free()
	return maxf(0.0, float(strategy_def.get("cooldown", 0.0)))

func _last_cast_tick_for_strategy(strategy_id: String, current_tick: int) -> int:
	var last_tick := -1
	for row in _event_rows:
		if int(row.get("tick", -1)) > current_tick:
			continue
		if str(row.get("type", "")) != "strategy_cast":
			continue
		if str(row.get("strategy_id", "")) != strategy_id:
			continue
		last_tick = int(row.get("tick", -1))
	return last_tick

func _is_strategy_triggered_at_tick(strategy_id: String, tick: int) -> bool:
	for row in _event_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if str(row.get("type", "")) == "strategy_cast" and str(row.get("strategy_id", "")) == strategy_id:
			return true
	return false
```

- [ ] **Step 6: Implement roster and log rendering APIs**

```gdscript
# scripts/observe/observe_screen.gd
func get_alive_roster_text() -> String:
	var ally_lines: Array[String] = []
	var enemy_lines: Array[String] = []
	for entity in _current_entities:
		if not bool(entity.get("alive", false)):
			continue
		var line := "%s %d" % [_unit_display_name_from_entity_id(str(entity.get("entity_id", ""))), int(round(float(entity.get("hp", 0.0))))]
		if str(entity.get("side", "")) == "enemy":
			enemy_lines.append(line)
		else:
			ally_lines.append(line)
	return "我方\n%s\n敌方\n%s" % ["\n".join(ally_lines), "\n".join(enemy_lines)]

func get_battle_log_text() -> String:
	var lines := _battle_report_formatter.build_recent_detail(_event_rows, _current_tick, "all", 18)
	return "\n".join(lines)
```

```gdscript
# scripts/observe/battle_report_formatter.gd (event_warning detail line)
"event_warning":
	var event_name := _resolver.event_name(str(row.get("event_id", "")))
	var seconds := int(row.get("warning_seconds", 5))
	return "第%d帧事件预告：%s将在 %d 秒后出现" % [tick, event_name, seconds]
```

- [ ] **Step 7: Run tests**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_strategy_card_runtime_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_roster_log_panel_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_strategy_cast_hud_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battle_report_brief_detail_test.gd`

Expected: all PASS.

- [ ] **Step 8: Commit**

```bash
git add scenes/observe/strategy_card_view.tscn scripts/observe/strategy_card_view.gd scripts/observe/observe_screen.gd scripts/observe/battle_report_formatter.gd tests/observe_strategy_card_runtime_test.gd tests/observe_roster_log_panel_test.gd tests/observe_strategy_cast_hud_test.gd tests/observe_battle_report_brief_detail_test.gd
git commit -m "feat: add strategy cards plus alive roster and rich battle logs"
```

## Task 5: Regression Pass, Accessibility Guard, And Final Verification

**Files:**
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_ui_interaction_accessibility_test.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_map_view_smoke_test.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_layer_hud_test.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [ ] **Step 1: Update accessibility test for new hierarchy (RED first)**

```gdscript
# tests/observe_ui_interaction_accessibility_test.gd additional checks
if screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/TokenHost") == null:
	_failures.append("missing TokenHost in battlefield panel")
if screen.get_node_or_null("LayoutRoot/RightColumn/BattleLogPanel/BattleLogScroll") == null:
	_failures.append("missing battle log scroll")
```

- [ ] **Step 2: Run accessibility and map smoke tests**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_ui_interaction_accessibility_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_map_view_smoke_test.gd`

Expected: FAIL before hierarchy updates are finalized, then PASS after fixes.

- [ ] **Step 3: Update compatibility helpers and finalize node-path migrations**

```gdscript
# scripts/observe/observe_screen.gd compatibility methods retained
func get_tick_text() -> String:
	return _tick_label.text

func get_event_text() -> String:
	return _event_label.text

func get_strategy_cast_text() -> String:
	return _strategy_cast_label.text
```

- [ ] **Step 4: Run focused observe regression suite**

Run:

`for t in tests/observe_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || exit 1; done`

Expected: observe-related tests PASS.

- [ ] **Step 5: Run full suite for release confidence**

Run:

`for t in tests/*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || exit 1; done`

Expected: full `tests/*.gd` PASS.

- [ ] **Step 6: Update handoff and commit**

```bash
git add tests/observe_ui_interaction_accessibility_test.gd tests/observe_map_view_smoke_test.gd tests/observe_layer_hud_test.gd docs/HANDOFF.md
git commit -m "test: finalize observe quadrant UI regressions and handoff notes"
```

## Execution Notes

1. Keep playback controls (`PauseButton`, seek slider, jump frame, speed select) functional throughout refactor.
2. Keep event timeline/filter controls functional; visual hierarchy can move but behavior must stay.
3. Preserve public helper methods used by tests to reduce brittle test rewrites.
4. Do not remove existing battle report center formatter behavior; extend it.

## Verification Checklist (before marking done)

1. Right-column vertical ratio is effectively 25/75 in runtime scene size.
2. No token overlap under crowded snapshot input.
3. Enemy names never regress to generic `"敌方单位"`.
4. Death marker is visibly present for linger ticks and then removed.
5. Strategy cards show trigger state and bottom-to-top cooldown fill.
6. Fonts on key labels are at or above design minimums.
7. All tests pass.
