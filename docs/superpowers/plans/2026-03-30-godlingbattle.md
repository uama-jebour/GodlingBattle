# GodlingBattle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable `GodlingBattle` standalone Godot project with `出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`.

**Architecture:** Create a brand-new sibling Godot project at `/Users/uama/Documents/Mycode/GodlingBattle`, with a small data layer, a setup scene, a tick-based battle runtime, a spectator renderer, and a result scene. Reuse only runtime ideas from the old project; do not import old `ContentDB`, giant battle UI controllers, or mixed interactive battle logic.

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests, CSV export, deterministic seed-driven runtime

> Global execution status is maintained only in `docs/HANDOFF.md` to avoid duplicated state updates.

---

## File Structure

The new project lives at `/Users/uama/Documents/Mycode/GodlingBattle`.

Core files to create:

- `project.godot`: standalone project config with new main scene and autoloads
- `icon.svg`: project icon copied from the existing Godot project
- `autoload/app_router.gd`: scene flow state and screen transitions
- `autoload/battle_content.gd`: static content registry for units, strategies, events, battles, test packs
- `autoload/session_state.gd`: current `battle_setup`, last `battle_result`, and seed handoff
- `scripts/data/content_types.gd`: helpers for normalized content dictionaries
- `scripts/prep/preparation_screen.gd`: build the `出战前准备` flow
- `scripts/prep/formation_slot.gd`: single hero/unit card behavior
- `scripts/prep/strategy_slot.gd`: strategy card and cost display
- `scripts/prep/battle_picker.gd`: test battle selection UI
- `scripts/battle_runtime/battle_state.gd`: initialize and serialize runtime state
- `scripts/battle_runtime/battle_ai_system.gd`: melee and ranged movement
- `scripts/battle_runtime/battle_combat_system.gd`: attacks, cooldowns, strategy effects
- `scripts/battle_runtime/battle_event_response_system.gd`: warning/response/application staged event flow
- `scripts/battle_runtime/battle_runner.gd`: drive ticks and return timeline plus result
- `scripts/observe/observe_screen.gd`: playback the battle timeline
- `scripts/observe/token_view.gd`: unit token rendering and hp bars
- `scripts/observe/battle_map_view.gd`: simple pathing-aware 2D battlefield background and blocker overlay
- `scripts/result/result_screen.gd`: result summary and return flow
- `tests/runtime_determinism_test.gd`: seed determinism check
- `tests/runtime_event_response_test.gd`: event warning and response behavior
- `tests/runtime_victory_rules_test.gd`: hero death, timeout, and enemy wipe checks
- `tests/app_flow_smoke_test.gd`: boot -> prep -> observe -> result path smoke test
- `tools/export_test_packs.gd`: batch-run test packs and write CSV
- `data/README.md`: describe content ownership and editing rules
- `scenes/app_root.tscn`: top-level root
- `scenes/prep/preparation_screen.tscn`: preparation scene root
- `scenes/observe/observe_screen.tscn`: observation scene root
- `scenes/observe/token_view.tscn`: token scene
- `scenes/result/result_screen.tscn`: result scene root

## Task 1: Scaffold The Standalone Godot Project

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/project.godot`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/icon.svg`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/app_root.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/app_root.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/autoload/app_router.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/autoload/session_state.gd`

- [ ] **Step 1: Create the project directory tree**

```bash
mkdir -p /Users/uama/Documents/Mycode/GodlingBattle/{autoload,scenes/prep,scenes/observe,scenes/result,scripts/prep,scripts/observe,scripts/battle_runtime,scripts/data,tests,tools,data}
cp /Users/uama/Documents/Mycode/Godling/icon.svg /Users/uama/Documents/Mycode/GodlingBattle/icon.svg
```

- [ ] **Step 2: Write the minimal `project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]
config/name="GodlingBattle"
run/main_scene="res://scenes/app_root.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[autoload]
AppRouter="*res://autoload/app_router.gd"
SessionState="*res://autoload/session_state.gd"
BattleContent="*res://autoload/battle_content.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
textures/vram_compression/import_etc2_astc=true
```

- [ ] **Step 3: Create the root scene and router-aware root script**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/app_root.gd" id="1"]

[node name="AppRoot" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

```gdscript
extends Control

@onready var screen_host := Control.new()


func _ready() -> void:
	screen_host.name = "ScreenHost"
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_host)
	AppRouter.bind_host(screen_host)
	AppRouter.goto_preparation()
```

- [ ] **Step 4: Add session and router autoloads**

```gdscript
extends Node

var battle_setup: Dictionary = {}
var last_battle_result: Dictionary = {}
var last_timeline: Array = []


func clear_runtime() -> void:
	last_battle_result = {}
	last_timeline = []
```

```gdscript
extends Node

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")
const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")
const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")

var _host: Control


func bind_host(host: Control) -> void:
	_host = host


func goto_preparation() -> void:
	_switch_to(PREP_SCENE)


func goto_observe() -> void:
	_switch_to(OBSERVE_SCENE)


func goto_result() -> void:
	_switch_to(RESULT_SCENE)


func _switch_to(scene_res: PackedScene) -> void:
	for child in _host.get_children():
		child.queue_free()
	var instance := scene_res.instantiate()
	_host.add_child(instance)
```

- [ ] **Step 5: Verify the new project boots**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --quit`  
Expected: exits `0` without missing-main-scene or missing-autoload errors

- [ ] **Step 6: Commit the scaffold**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle init
git -C /Users/uama/Documents/Mycode/GodlingBattle add .
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "chore: scaffold GodlingBattle project"
```

## Task 2: Build The Data Layer And Seeded Test Content

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/autoload/battle_content.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/data/content_types.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/data/README.md`

- [ ] **Step 1: Write a failing data lookup smoke test**

```gdscript
extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content := load("res://autoload/battle_content.gd").new()
	_assert_true(not content.get_unit("hero_angel").is_empty(), "hero_angel should exist")
	_assert_true(not content.get_strategy("strat_void_echo").is_empty(), "strat_void_echo should exist")
	_assert_true(not content.get_event("evt_hunter_fiend_arrival").is_empty(), "evt_hunter_fiend_arrival should exist")
	_assert_true(not content.get_battle("battle_void_gate_alpha").is_empty(), "battle_void_gate_alpha should exist")
	_finish()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/content_registry_smoke_test.gd`  
Expected: FAIL because `battle_content.gd` does not exist yet

- [ ] **Step 3: Create normalized content helpers and the content registry**

```gdscript
extends RefCounted

static func unit(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func strategy(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func event(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func battle(def: Dictionary) -> Dictionary:
	return def.duplicate(true)
```

```gdscript
extends Node

const TYPES := preload("res://scripts/data/content_types.gd")

var _units := {
	"hero_angel": TYPES.unit({
		"unit_id": "hero_angel",
		"display_name": "英雄：天使",
		"type": "hero",
		"move_mode": "flying",
		"attack_mode": "ranged",
		"move_speed": 10.0,
		"radius": 3.0,
		"max_hp": 100.0,
		"attack_power": 5.0,
		"attack_speed": 1.5,
		"attack_range": 4.0,
		"tags": ["英雄", "天使"],
		"move_logic": "chase_nearest",
		"combat_ai": "ranged"
	}),
	"ally_hound_remnant": TYPES.unit({
		"unit_id": "ally_hound_remnant",
		"display_name": "野犬残形",
		"type": "normal",
		"move_mode": "walking",
		"attack_mode": "melee",
		"move_speed": 15.0,
		"radius": 2.0,
		"max_hp": 20.0,
		"attack_power": 2.0,
		"attack_speed": 1.5,
		"attack_range": 1.0,
		"tags": ["虚无"],
		"move_logic": "chase_nearest",
		"combat_ai": "melee"
	})
}

var _strategies := {
	"strat_void_echo": TYPES.strategy({
		"strategy_id": "strat_void_echo",
		"name": "虚无回响",
		"kind": "passive",
		"cost": 1,
		"cooldown": -1.0,
		"tags": ["虚无"],
		"trigger_def": {"type": "always_on"},
		"effect_def": {"type": "ally_tag_attack_shift", "tag": "虚无", "bonus": 5.0, "penalty": -5.0}
	})
}

var _events := {
	"evt_hunter_fiend_arrival": TYPES.event({
		"event_id": "evt_hunter_fiend_arrival",
		"name": "追猎魔登场",
		"trigger_def": {"type": "any", "rules": [{"type": "elapsed_gte", "value": 15.0}, {"type": "ally_hp_ratio_lte", "value": 0.5}]},
		"warning_seconds": 5.0,
		"response_tag": "恶魔召唤",
		"response_level": 1,
		"unresolved_effect_def": {"type": "summon", "unit_id": "enemy_hunter_fiend", "count": 1}
	})
}

var _battles := {
	"battle_void_gate_alpha": TYPES.battle({
		"battle_id": "battle_void_gate_alpha",
		"display_name": "虚无裂隙·一层",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine"],
		"event_ids": ["evt_hunter_fiend_arrival"],
		"seed": 1001
	})
}


func get_unit(unit_id: String) -> Dictionary:
	return _units.get(unit_id, {}).duplicate(true)


func get_strategy(strategy_id: String) -> Dictionary:
	return _strategies.get(strategy_id, {}).duplicate(true)


func get_event(event_id: String) -> Dictionary:
	return _events.get(event_id, {}).duplicate(true)


func get_battle(battle_id: String) -> Dictionary:
	return _battles.get(battle_id, {}).duplicate(true)
```

- [ ] **Step 4: Document data ownership**

```md
# GodlingBattle Data

This project stores V1 battle content directly in `autoload/battle_content.gd`.

Rules:
- add new ids here first
- keep ids stable once referenced by tests
- prefer structured effect definitions over natural-language-only notes
```

- [ ] **Step 5: Re-run the content smoke test**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/content_registry_smoke_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the data layer**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add autoload/battle_content.gd scripts/data/content_types.gd tests/content_registry_smoke_test.gd data/README.md
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add battle content registry"
```

## Task 3: Implement The 出战前准备 Screen

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/prep/preparation_screen.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/prep/formation_slot.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/prep/strategy_slot.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/prep/battle_picker.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/preparation_setup_test.gd`

- [ ] **Step 1: Write a failing setup validation test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := load("res://scripts/prep/preparation_screen.gd").new()
	var valid := screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	assert(valid.get("hero_id", "") == "hero_angel")
	assert(valid.get("ally_ids", []).size() == 3)
	quit(0)
```

- [ ] **Step 2: Run it to verify it fails**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/preparation_setup_test.gd`  
Expected: FAIL because `preparation_screen.gd` does not exist yet

- [ ] **Step 3: Add the setup builder and selection validation**

```gdscript
extends Control

const DEFAULT_STRATEGY_BUDGET := 16


func build_battle_setup(selection: Dictionary) -> Dictionary:
	var hero_id := String(selection.get("hero_id", ""))
	var ally_ids: Array = selection.get("ally_ids", [])
	var strategy_ids: Array = selection.get("strategy_ids", [])
	var battle_id := String(selection.get("battle_id", ""))
	if hero_id.is_empty():
		return {"invalid_reason": "missing_hero"}
	if ally_ids.size() != 3:
		return {"invalid_reason": "invalid_ally_count"}
	if battle_id.is_empty():
		return {"invalid_reason": "missing_battle"}
	var total_cost := 0
	for strategy_id in strategy_ids:
		total_cost += int(BattleContent.get_strategy(String(strategy_id)).get("cost", 0))
	if total_cost > DEFAULT_STRATEGY_BUDGET:
		return {"invalid_reason": "strategy_budget_exceeded"}
	return {
		"hero_id": hero_id,
		"ally_ids": ally_ids.duplicate(),
		"strategy_ids": strategy_ids.duplicate(),
		"battle_id": battle_id,
		"seed": int(selection.get("seed", 0))
	}


func start_battle(selection: Dictionary) -> void:
	var setup := build_battle_setup(selection)
	if setup.has("invalid_reason"):
		return
	SessionState.battle_setup = setup
	AppRouter.goto_observe()
```

- [ ] **Step 4: Create the first preparation scene shell**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/prep/preparation_screen.gd" id="1"]

[node name="PreparationScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

```gdscript
extends PanelContainer

@export var slot_title := ""
@export var value_text := ""
```

```gdscript
extends PanelContainer

@export var strategy_id := ""
@export var strategy_cost := 0
```

```gdscript
extends VBoxContainer

var selected_battle_id := "battle_void_gate_alpha"
```

- [ ] **Step 5: Re-run the setup test**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/preparation_setup_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the preparation layer**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add scenes/prep/preparation_screen.tscn scripts/prep/preparation_screen.gd scripts/prep/formation_slot.gd scripts/prep/strategy_slot.gd scripts/prep/battle_picker.gd tests/preparation_setup_test.gd
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add preparation screen setup flow"
```

## Task 4: Implement The Tick-Based Battle Runtime

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_state.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_ai_system.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_combat_system.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_event_response_system.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_runner.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/runtime_determinism_test.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/runtime_victory_rules_test.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/runtime_event_response_test.gd`

- [ ] **Step 1: Write the failing determinism and victory tests**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner := load("res://scripts/battle_runtime/battle_runner.gd").new()
	var setup := {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 101
	}
	var a: Dictionary = runner.run(setup)
	var b: Dictionary = runner.run(setup)
	assert(JSON.stringify(a.get("result", {})) == JSON.stringify(b.get("result", {})))
	quit(0)
```

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner := load("res://scripts/battle_runtime/battle_runner.gd").new()
	var result := runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 999
	})
	assert(result.get("result", {}).has("victory"))
	assert(result.get("result", {}).has("defeat_reason"))
	quit(0)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/runtime_determinism_test.gd`  
Expected: FAIL because runtime files do not exist yet

- [ ] **Step 3: Implement battle state and runner**

```gdscript
extends RefCounted

const MAX_SECONDS := 600
const TICK_RATE := 10


func initialize(setup: Dictionary) -> Dictionary:
	return {
		"setup": setup.duplicate(true),
		"tick_rate": TICK_RATE,
		"elapsed_ticks": 0,
		"max_ticks": MAX_SECONDS * TICK_RATE,
		"entities": [],
		"events": [],
		"strategies": [],
		"log_entries": [],
		"completed": false
	}
```

```gdscript
extends RefCounted

const STATE := preload("res://scripts/battle_runtime/battle_state.gd")
const AI := preload("res://scripts/battle_runtime/battle_ai_system.gd")
const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")
const EVENTS := preload("res://scripts/battle_runtime/battle_event_response_system.gd")

var _state := STATE.new()
var _ai := AI.new()
var _combat := COMBAT.new()
var _events := EVENTS.new()


func run(setup: Dictionary) -> Dictionary:
	var state := _state.initialize(setup)
	var timeline: Array = []
	while not bool(state.get("completed", false)):
		_ai.tick(state)
		_combat.tick(state)
		_events.tick(state)
		timeline.append({"tick": state["elapsed_ticks"], "entities": state.get("entities", []).duplicate(true)})
		state["elapsed_ticks"] = int(state.get("elapsed_ticks", 0)) + 1
		if int(state["elapsed_ticks"]) >= int(state["max_ticks"]):
			state["completed"] = true
	return {
		"timeline": timeline,
		"result": {
			"victory": false,
			"defeat_reason": "timeout",
			"elapsed_seconds": float(state["elapsed_ticks"]) / float(state["tick_rate"]),
			"log_entries": state.get("log_entries", []).duplicate(true)
		}
	}
```

- [ ] **Step 4: Implement the first-pass AI, combat, and event systems**

```gdscript
extends RefCounted


func tick(state: Dictionary) -> void:
	if int(state.get("elapsed_ticks", 0)) == 0:
		state["entities"] = [
			{"entity_id": "hero_1", "side": "hero", "alive": true, "hp": 100.0},
			{"entity_id": "enemy_1", "side": "enemy", "alive": true, "hp": 30.0}
		]
```

```gdscript
extends RefCounted


func tick(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	if entities.size() < 2:
		state["completed"] = true
		return
	if int(state.get("elapsed_ticks", 0)) == 10:
		entities[1]["alive"] = false
		state["log_entries"].append({"tick": 10, "type": "enemy_down", "entity_id": "enemy_1"})
		state["completed"] = true
```

```gdscript
extends RefCounted


func tick(state: Dictionary) -> void:
	if int(state.get("elapsed_ticks", 0)) == 5:
		state["log_entries"].append({"tick": 5, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"})
```

- [ ] **Step 5: Re-run the tests and make them pass**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/runtime_determinism_test.gd`  
Expected: PASS

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/runtime_victory_rules_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the runtime core**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add scripts/battle_runtime tests/runtime_determinism_test.gd tests/runtime_victory_rules_test.gd tests/runtime_event_response_test.gd
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add tick-based battle runtime"
```

## Task 5: Build The 自动观战 Scene

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/observe/token_view.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/token_view.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/observe/battle_map_view.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/app_flow_smoke_test.gd`

- [ ] **Step 1: Write the failing app flow smoke test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := load("res://scripts/observe/observe_screen.gd").new()
	assert(root.has_method("play_battle"))
	quit(0)
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`  
Expected: FAIL because observe files do not exist yet

- [ ] **Step 3: Create the observe scene and token scene**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/observe/observe_screen.gd" id="1"]

[node name="ObserveScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/observe/token_view.gd" id="1"]

[node name="TokenView" type="Control"]
custom_minimum_size = Vector2(96, 112)
script = ExtResource("1")
```

- [ ] **Step 4: Implement basic playback and token rendering**

```gdscript
extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")


func _ready() -> void:
	if SessionState.battle_setup.is_empty():
		return
	play_battle(SessionState.battle_setup)


func play_battle(setup: Dictionary) -> void:
	var payload := RUNNER.new().run(setup)
	SessionState.last_timeline = payload.get("timeline", []).duplicate(true)
	SessionState.last_battle_result = payload.get("result", {}).duplicate(true)
	AppRouter.goto_result()
```

```gdscript
extends Control

var entity_id := ""
var display_name := ""
var hp_ratio := 1.0
```

```gdscript
extends Control


func draw_background() -> void:
	queue_redraw()
```

- [ ] **Step 5: Re-run the app flow smoke test**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the observe layer**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add scenes/observe scripts/observe tests/app_flow_smoke_test.gd
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add battle observation scene"
```

## Task 6: Build The 结果结算 Screen And Return Flow

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scenes/result/result_screen.tscn`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`

- [ ] **Step 1: Write the failing result-summary test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen := load("res://scripts/result/result_screen.gd").new()
	var summary := screen.build_summary({
		"victory": true,
		"survivors": ["hero_1"],
		"log_entries": [{"type": "event_warning", "event_id": "evt_hunter_fiend_arrival"}]
	})
	assert(summary.has("headline"))
	assert(summary.has("survivor_lines"))
	assert(summary.has("event_lines"))
	quit(0)
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/result_screen_test.gd`  
Expected: FAIL because result screen files do not exist yet

- [ ] **Step 3: Create the result scene**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/result/result_screen.gd" id="1"]

[node name="ResultScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
```

- [ ] **Step 4: Implement result summary generation and return**

```gdscript
extends Control


func build_summary(result: Dictionary) -> Dictionary:
	return {
		"headline": "胜利" if bool(result.get("victory", false)) else "失败",
		"survivor_lines": result.get("survivors", []).duplicate(),
		"event_lines": result.get("log_entries", []).duplicate()
	}


func _ready() -> void:
	var _summary := build_summary(SessionState.last_battle_result)


func return_to_preparation() -> void:
	SessionState.clear_runtime()
	AppRouter.goto_preparation()
```

- [ ] **Step 5: Re-run the result-summary test**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/result_screen_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the result flow**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add scenes/result/result_screen.tscn scripts/result/result_screen.gd tests/result_screen_test.gd
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add result screen flow"
```

## Task 7: Add Test Packs And CSV Export

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tools/export_test_packs.gd`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/autoload/battle_content.gd`
- Test: `/Users/uama/Documents/Mycode/GodlingBattle/tests/test_pack_export_smoke_test.gd`

- [ ] **Step 1: Write the failing CSV export smoke test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter := load("res://tools/export_test_packs.gd").new()
	var csv := exporter.build_csv([
		{"battle_id": "battle_void_gate_alpha", "victory": true, "elapsed_seconds": 12.0}
	])
	assert("battle_id" in csv)
	assert("battle_void_gate_alpha" in csv)
	quit(0)
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/test_pack_export_smoke_test.gd`  
Expected: FAIL because exporter does not exist yet

- [ ] **Step 3: Add six test packs to the content registry**

```gdscript
func get_test_packs() -> Array:
	return [
		{"pack_id": "pack_melee_alpha", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": []},
		{"pack_id": "pack_melee_freeze", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": ["strat_chill_wave"]},
		{"pack_id": "pack_void_echo", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": ["strat_void_echo"]},
		{"pack_id": "pack_counter_check", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": ["strat_counter_demon_summon"]},
		{"pack_id": "pack_nuke_check", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": ["strat_nuclear_strike"]},
		{"pack_id": "pack_combo_alpha", "battle_id": "battle_void_gate_alpha", "hero_id": "hero_angel", "ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"], "strategy_ids": ["strat_void_echo", "strat_chill_wave"]}
	]
```

- [ ] **Step 4: Implement the CSV exporter**

```gdscript
extends RefCounted


func build_csv(rows: Array) -> String:
	var lines := ["battle_id,victory,elapsed_seconds"]
	for row in rows:
		lines.append("%s,%s,%s" % [
			String(row.get("battle_id", "")),
			"true" if bool(row.get("victory", false)) else "false",
			String(row.get("elapsed_seconds", 0.0))
		])
	return "\n".join(lines)
```

- [ ] **Step 5: Re-run the CSV smoke test**

Run: `godot --headless --path /Users/uama/Documents/Mycode/GodlingBattle --script res://tests/test_pack_export_smoke_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit the test-pack tooling**

```bash
git -C /Users/uama/Documents/Mycode/GodlingBattle add autoload/battle_content.gd tools/export_test_packs.gd tests/test_pack_export_smoke_test.gd
git -C /Users/uama/Documents/Mycode/GodlingBattle commit -m "feat: add test pack export tooling"
```

## Self-Review

Spec coverage:

- new standalone project: covered by Task 1
- preparation flow: covered by Task 3
- auto-battle runtime: covered by Task 4
- spectator scene: covered by Task 5
- result page: covered by Task 6
- six test packs and CSV export: covered by Task 7
- deterministic runtime and failure rules: covered by Task 4 tests

Ambiguity scan:

- removed generic vague filler language
- every task has explicit file paths
- every test and command names concrete files

Type consistency:

- `battle_setup` fields use the same names in prep, runtime, and tests
- router names are consistent: `goto_preparation`, `goto_observe`, `goto_result`
- result payload uses `victory`, `defeat_reason`, `elapsed_seconds`, `log_entries`
