# GodlingBattle Phase 13 Battle Report Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a readable dual-layer battle report center in Observe and fully remove English IDs from Result screen output.

**Architecture:** Add a shared display-name resolver for ID-to-Chinese rendering, introduce an Observe log formatter that emits brief/detail report rows, and refactor Observe/Result UI to consume formatter output instead of raw runtime keys.

**Tech Stack:** Godot 4.6, GDScript, headless test scripts (`tests/*.gd`)

---

## File Structure

Core files for this phase task:

- `scripts/ui/display_name_resolver.gd`: shared Chinese display-name resolver
- `tests/display_name_resolver_test.gd`: resolver behavior regression
- `scripts/result/result_screen.gd`: result summary localization integration
- `tests/result_localization_no_english_ids_test.gd`: no-English-ID guard
- `scripts/observe/battle_report_formatter.gd`: brief/detail report conversion
- `scenes/observe/observe_screen.tscn`: report-center nodes (overview/brief/detail)
- `scripts/observe/observe_screen.gd`: report-center rendering + expand/collapse behavior
- `tests/observe_battle_report_brief_detail_test.gd`: observe dual-layer behavior test
- `tests/observe_event_timeline_filter_test.gd`: filter + report sync guard
- `docs/HANDOFF.md`: global status update only after verification

## Task 1: Shared Display Name Resolver

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/ui/display_name_resolver.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/display_name_resolver_test.gd`

- [ ] **Step 1: Write failing resolver test (RED)**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var resolver_script: GDScript = load("res://scripts/ui/display_name_resolver.gd")
	if resolver_script == null:
		_failures.append("missing display_name_resolver.gd")
		_finish()
		return
	var resolver: Object = resolver_script.new()

	var unit_name := String(resolver.call("unit_name_from_unit_id", "hero_angel"))
	if unit_name != "英雄：天使":
		_failures.append("unit_name_from_unit_id should map hero_angel")

	var entity_name := String(resolver.call("unit_name_from_entity_id", "enemy_wandering_demon_4"))
	if entity_name.find("enemy_") != -1:
		_failures.append("unit_name_from_entity_id should not expose raw enemy id")

	var strategy_name := String(resolver.call("strategy_name", "strat_chill_wave"))
	if strategy_name != "寒潮冲击":
		_failures.append("strategy_name should map strat_chill_wave")

	var event_name := String(resolver.call("event_name", "evt_hunter_fiend_arrival"))
	if event_name != "追猎魔登场":
		_failures.append("event_name should map evt_hunter_fiend_arrival")

	var battle_name := String(resolver.call("battle_name", "battle_void_gate_beta"))
	if battle_name != "虚无裂隙·二层":
		_failures.append("battle_name should map battle_void_gate_beta")

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
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/display_name_resolver_test.gd`

Expected: FAIL with `missing display_name_resolver.gd`.

- [ ] **Step 3: Implement resolver with ID fallback stripping**

```gdscript
extends RefCounted

const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")


func unit_name_from_unit_id(unit_id: String) -> String:
	if unit_id.is_empty():
		return "未知单位"
	var content: Node = BATTLE_CONTENT.new()
	var unit_def: Dictionary = content.get_unit(unit_id)
	content.free()
	if unit_def.is_empty():
		return _unknown_unit_text(unit_id)
	return String(unit_def.get("display_name", unit_id))


func unit_name_from_entity_id(entity_id: String) -> String:
	if entity_id.is_empty():
		return "未知单位"
	var unit_id := entity_id
	var split_index := entity_id.rfind("_")
	if split_index > 0:
		var suffix := entity_id.substr(split_index + 1)
		if suffix.is_valid_int():
			unit_id = entity_id.substr(0, split_index)
	return unit_name_from_unit_id(unit_id)


func strategy_name(strategy_id: String) -> String:
	if strategy_id.is_empty():
		return "未知战技"
	var content: Node = BATTLE_CONTENT.new()
	var strategy_def: Dictionary = content.get_strategy(strategy_id)
	content.free()
	if strategy_def.is_empty():
		return "未知战技"
	return String(strategy_def.get("name", strategy_id))


func event_name(event_id: String) -> String:
	if event_id.is_empty():
		return "未知事件"
	var content: Node = BATTLE_CONTENT.new()
	var event_def: Dictionary = content.get_event(event_id)
	content.free()
	if event_def.is_empty():
		return "未知事件"
	return String(event_def.get("name", event_id))


func battle_name(battle_id: String) -> String:
	if battle_id.is_empty():
		return "未知关卡"
	var content: Node = BATTLE_CONTENT.new()
	var battle_def: Dictionary = content.get_battle(battle_id)
	content.free()
	if battle_def.is_empty():
		return "未知关卡"
	return String(battle_def.get("display_name", battle_id))


func _unknown_unit_text(unit_id: String) -> String:
	if unit_id.begins_with("enemy_"):
		return "未知敌方单位"
	if unit_id.begins_with("ally_"):
		return "未知友军单位"
	if unit_id.begins_with("hero_"):
		return "未知英雄单位"
	return "未知单位"
```

- [ ] **Step 4: Run test to verify it passes**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/display_name_resolver_test.gd`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/display_name_resolver.gd tests/display_name_resolver_test.gd
git commit -m "feat: add shared display name resolver for localized battle logs"
```

## Task 2: Result Screen No-English-ID Guarantee

**Files:**
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/result_localization_no_english_ids_test.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/tests/result_setup_snapshot_test.gd`

- [ ] **Step 1: Add/refresh failing no-English-ID test (RED)**

```gdscript
extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")

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
		"strategy_ids": ["strat_void_echo", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	}
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel_0"],
		"casualties": ["enemy_wandering_demon_4", "enemy_animated_machine_5"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}],
		"log_entries": [{"tick": 5, "type": "strategy_cast", "strategy_id": "strat_nuclear_strike"}]
	}

	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var joined := ""
	for path in ["Layout/SurvivorLabel", "Layout/CasualtyLabel", "Layout/EventLabel", "Layout/StrategyLabel", "Layout/StrategyCastSummaryLabel", "Layout/SetupSnapshotLabel"]:
		var label := screen.get_node_or_null(path) as Label
		if label != null:
			joined += String(label.text) + "\n"

	if joined.find("hero_") != -1 or joined.find("ally_") != -1 or joined.find("enemy_") != -1 or joined.find("strat_") != -1 or joined.find("battle_") != -1:
		_failures.append("result text should not expose english IDs")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/result_localization_no_english_ids_test.gd`

Expected: FAIL if any raw ID remains.

- [ ] **Step 3: Refactor result summary through resolver only**

```gdscript
const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")
var _name_resolver := DISPLAY_NAME_RESOLVER.new()

func _map_unit_names(rows: Array) -> Array:
	var mapped: Array = []
	for row in rows:
		mapped.append(_name_resolver.unit_name_from_entity_id(str(row)))
	return mapped

func _map_event_names(rows: Array) -> Array:
	var mapped: Array = []
	for row in rows:
		mapped.append(_name_resolver.event_name(str(row.get("event_id", ""))))
	return mapped

func _map_strategy_names(rows: Array) -> Array:
	var mapped: Array = []
	for row in rows:
		mapped.append(_name_resolver.strategy_name(str(row.get("strategy_id", ""))))
	return mapped

func _build_setup_snapshot_lines(battle_setup: Dictionary) -> Array:
	return [
		"英雄：%s" % _name_resolver.unit_name_from_unit_id(str(battle_setup.get("hero_id", ""))),
		"友军：%s" % ", ".join(_map_setup_unit_rows(battle_setup.get("ally_ids", []))),
		"战技：%s" % ", ".join(_map_setup_strategy_rows(battle_setup.get("strategy_ids", []))),
		"关卡：%s" % _name_resolver.battle_name(str(battle_setup.get("battle_id", ""))),
		"种子：%s" % str(battle_setup.get("seed", ""))
	]
```

- [ ] **Step 4: Run tests to verify Result behavior**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/result_localization_no_english_ids_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/result_setup_snapshot_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/result_strategy_cast_summary_test.gd`

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/result/result_screen.gd tests/result_localization_no_english_ids_test.gd tests/result_setup_snapshot_test.gd
git commit -m "fix: remove raw english ids from result summary output"
```

## Task 3: Observe Dual-Layer Battle Report Center

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/battle_report_formatter.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_battle_report_brief_detail_test.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/tests/observe_event_timeline_filter_test.gd`

- [ ] **Step 1: Add failing observe report-center test (RED)**

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
	session_state.last_timeline = [{"tick": 0, "entities": []}, {"tick": 1, "entities": []}]
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel_0"],
		"casualties": ["enemy_wandering_demon_3"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"log_entries": [
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	if not screen.has_method("get_battle_overview_text"):
		_failures.append("missing get_battle_overview_text")
	if not screen.has_method("get_tick_summary_text"):
		_failures.append("missing get_tick_summary_text")
	if not screen.has_method("get_detail_log_visible"):
		_failures.append("missing get_detail_log_visible")

	if String(screen.call("get_battle_overview_text")).find("战况总览") == -1:
		_failures.append("overview should include 战况总览")

	var toggle := screen.get_node_or_null("EventPanel/DetailToggleButton") as Button
	if toggle == null:
		_failures.append("missing DetailToggleButton")
	else:
		toggle.emit_signal("pressed")
		await process_frame
		if not bool(screen.call("get_detail_log_visible")):
			_failures.append("detail log should be visible after toggle")

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
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battle_report_brief_detail_test.gd`

Expected: FAIL with missing methods/nodes.

- [ ] **Step 3: Implement formatter + Observe panel integration**

```gdscript
# scripts/observe/battle_report_formatter.gd
extends RefCounted

const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")
var _resolver := DISPLAY_NAME_RESOLVER.new()

func build_tick_brief(rows: Array, tick: int, filter_type: String) -> Array[String]:
	var lines: Array[String] = []
	for row in rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if filter_type != "all" and str(row.get("type", "")) != filter_type:
			continue
		lines.append(_brief_line(row))
	return lines

func build_tick_detail(rows: Array, tick: int, filter_type: String) -> Array[String]:
	var lines: Array[String] = []
	for row in rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if filter_type != "all" and str(row.get("type", "")) != filter_type:
			continue
		lines.append(_detail_line(row))
	return lines

func _brief_line(row: Dictionary) -> String:
	# type-to-Chinese summary conversion
	return "..."

func _detail_line(row: Dictionary) -> String:
	# tactical sentence conversion
	return "..."
```

```gdscript
# scripts/observe/observe_screen.gd (key additions)
@onready var _detail_toggle_button: Button = $EventPanel/DetailToggleButton
@onready var _detail_log_list: ItemList = $EventPanel/DetailLogList
var _detail_log_visible := false

func _on_detail_toggle_pressed() -> void:
	_detail_log_visible = not _detail_log_visible
	_refresh_detail_log()

func get_detail_log_visible() -> bool:
	return _detail_log_visible
```

- [ ] **Step 4: Run Observe tests**

Run:

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battle_report_brief_detail_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_event_timeline_filter_test.gd`

`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_playback_controls_test.gd`

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/observe/battle_report_formatter.gd scenes/observe/observe_screen.tscn scripts/observe/observe_screen.gd tests/observe_battle_report_brief_detail_test.gd tests/observe_event_timeline_filter_test.gd
git commit -m "feat: add dual-layer observe battle report center"
```

## Task 4: Verification And Handoff Update

**Files:**
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [ ] **Step 1: Run targeted localization/report regression**

Run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/display_name_resolver_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/result_localization_no_english_ids_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battle_report_brief_detail_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/ui_readability_localization_test.gd
```

Expected: all PASS.

- [ ] **Step 2: Run full regression**

Run:

```bash
for t in $(rg --files tests -g '*.gd' | sort); do
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break
done
```

Expected: all tests pass (count should increase by newly added tests).

- [ ] **Step 3: Update HANDOFF global status**

Update:
- add `Phase13 Task1` entry (battle report center + result localization)
- update test total count in `验证结果（本次）`
- update next-phase suggestion after Phase13 completion

- [ ] **Step 4: Final commit**

```bash
git add docs/HANDOFF.md
git commit -m "docs: update handoff for phase13 battle report center completion"
```

## Verification Checklist

- `tests/display_name_resolver_test.gd` pass
- `tests/result_localization_no_english_ids_test.gd` pass
- `tests/observe_battle_report_brief_detail_test.gd` pass
- no English IDs in Observe/Result text output
- full `tests/*.gd` pass
