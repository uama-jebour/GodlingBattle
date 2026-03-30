# GodlingBattle Phase 4 UI Productization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current logic-complete loop into a visible and readable product loop where preparation, observe, and result screens all render concrete UI and keep the same deterministic runtime behavior.

**Architecture:** Keep runtime/data contracts unchanged (`battle_setup`, timeline frames, `battle_result`) and only strengthen presentation + flow orchestration at scene/script boundaries. Add UI smoke tests first, then implement minimum UI nodes and binding logic to make those tests pass.

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests, deterministic tick runtime

---

## File Structure

Core files for this phase:

- `scenes/prep/preparation_screen.tscn`: preparation screen visual skeleton and named UI anchors
- `scripts/prep/preparation_screen.gd`: selection defaults, summary rendering, start action, validation feedback
- `scripts/prep/formation_slot.gd`: hero/ally slot rendering helper
- `scripts/prep/strategy_slot.gd`: strategy pill rendering helper with cost text
- `scripts/prep/battle_picker.gd`: battle selection summary rendering helper
- `scenes/observe/battle_map_view.tscn`: map view scene node to host map background script
- `scripts/observe/battle_map_view.gd`: battlefield background + blocker overlay renderer
- `scripts/observe/observe_screen.gd`: map + HUD + event/strategy hint projection from timeline/logs
- `scenes/result/result_screen.tscn`: result report UI shell and return button
- `scripts/result/result_screen.gd`: summary-to-UI binding and return flow
- `tests/preparation_screen_ui_smoke_test.gd`: preparation UI anchors and default text smoke
- `tests/preparation_start_battle_ui_test.gd`: start flow validation feedback and runtime handoff smoke
- `tests/observe_map_view_smoke_test.gd`: observe map + HUD readable feed smoke
- `tests/result_screen_ui_smoke_test.gd`: result report UI field mapping smoke
- `tests/app_flow_smoke_test.gd`: full boot -> prep -> observe -> result -> prep loop contract
- `docs/HANDOFF.md`: phase status and next recommended command update

## Task 1: Build Visible 出战前准备 Screen Shell

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/prep/preparation_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_screen_ui_smoke_test.gd`

- [ ] **Step 1: Write a failing preparation UI smoke test**

```gdscript
extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("Layout/TitleLabel") != null)
	assert(screen.get_node_or_null("Layout/SelectionSummary") != null)
	assert(screen.get_node_or_null("Layout/StartBattleButton") != null)
	assert((screen.get_node("Layout/TitleLabel") as Label).text == "出战前准备")
	screen.queue_free()
	await process_frame
	quit(0)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_screen_ui_smoke_test.gd`  
Expected: FAIL because `Layout/*` named nodes do not exist yet

- [ ] **Step 3: Add preparation scene UI skeleton**

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

[node name="Layout" type="VBoxContainer" parent="."]
layout_mode = 2
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 48.0
offset_top = 36.0
offset_right = -48.0
offset_bottom = -36.0
theme_override_constants/separation = 16

[node name="TitleLabel" type="Label" parent="Layout"]
layout_mode = 2
text = "出战前准备"

[node name="SelectionSummary" type="Label" parent="Layout"]
layout_mode = 2
text = "加载中..."
autowrap_mode = 2

[node name="BattleSummary" type="Label" parent="Layout"]
layout_mode = 2
text = ""
autowrap_mode = 2

[node name="ErrorLabel" type="Label" parent="Layout"]
layout_mode = 2
text = ""

[node name="StartBattleButton" type="Button" parent="Layout"]
layout_mode = 2
text = "开始观战"
```

- [ ] **Step 4: Bind default selection and summary text in preparation script**

```gdscript
extends Control

const DEFAULT_STRATEGY_BUDGET := 16

@onready var _summary_label: Label = $Layout/SelectionSummary
@onready var _battle_summary_label: Label = $Layout/BattleSummary
@onready var _error_label: Label = $Layout/ErrorLabel
@onready var _start_button: Button = $Layout/StartBattleButton

var _current_selection: Dictionary = {}


func _ready() -> void:
	_current_selection = _build_default_selection()
	_render_selection_summary(_current_selection)
	_start_button.pressed.connect(_on_start_pressed)


func _build_default_selection() -> Dictionary:
	return {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	}


func _render_selection_summary(selection: Dictionary) -> void:
	_summary_label.text = "英雄: %s | 友军: %s" % [
		String(selection.get("hero_id", "")),
		", ".join(selection.get("ally_ids", []))
	]
	_battle_summary_label.text = "关卡: %s | 策略: %s" % [
		String(selection.get("battle_id", "")),
		", ".join(selection.get("strategy_ids", []))
	]
	_error_label.text = ""


func _on_start_pressed() -> void:
	start_battle(_current_selection)
```

- [ ] **Step 5: Re-run preparation UI smoke test**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_screen_ui_smoke_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/prep/preparation_screen.tscn scripts/prep/preparation_screen.gd tests/preparation_screen_ui_smoke_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add visible preparation screen shell"
```

## Task 2: Wire Preparation Slot Components And Start Feedback

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/formation_slot.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/strategy_slot.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/battle_picker.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_start_battle_ui_test.gd`

- [ ] **Step 1: Write a failing start-battle UI test**

```gdscript
extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("start_battle", {
		"hero_id": "",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	await process_frame
	var error_label := screen.get_node("Layout/ErrorLabel") as Label
	assert(not error_label.text.is_empty())
	screen.queue_free()
	await process_frame
	quit(0)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_start_battle_ui_test.gd`  
Expected: FAIL because invalid setup currently does not show UI feedback

- [ ] **Step 3: Implement slot component render helpers**

```gdscript
# formation_slot.gd
extends PanelContainer

@export var slot_title := ""
@export var value_text := ""


func render(title: String, value: String) -> void:
	slot_title = title
	value_text = value
```

```gdscript
# strategy_slot.gd
extends PanelContainer

@export var strategy_id := ""
@export var strategy_cost := 0


func render(id: String, cost: int) -> void:
	strategy_id = id
	strategy_cost = cost
```

```gdscript
# battle_picker.gd
extends VBoxContainer

var selected_battle_id := "battle_void_gate_alpha"


func set_selected_battle_id(battle_id: String) -> void:
	selected_battle_id = battle_id
```

- [ ] **Step 4: Surface validation error text in preparation script**

```gdscript
func start_battle(selection: Dictionary) -> void:
	var setup := build_battle_setup(selection)
	if setup.has("invalid_reason"):
		_error_label.text = "无法开始出战: %s" % String(setup.get("invalid_reason", "unknown"))
		return
	_error_label.text = ""
	SessionState.battle_setup = setup
	AppRouter.goto_observe()
```

- [ ] **Step 5: Re-run start-battle UI test**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_start_battle_ui_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/prep/formation_slot.gd scripts/prep/strategy_slot.gd scripts/prep/battle_picker.gd scripts/prep/preparation_screen.gd tests/preparation_start_battle_ui_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add preparation start validation feedback"
```

## Task 3: Add Battlefield Map View And Readable Observe Feed

**Files:**
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/battle_map_view.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/battle_map_view.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_map_view_smoke_test.gd`

- [ ] **Step 1: Write a failing observe map smoke test**

```gdscript
extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SessionState.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	SessionState.last_timeline = [{"tick": 0, "entities": []}]
	SessionState.last_battle_result = {"log_entries": []}
	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("BattleMap") != null)
	screen.queue_free()
	await process_frame
	quit(0)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_map_view_smoke_test.gd`  
Expected: FAIL because observe screen does not provide `BattleMap` node yet

- [ ] **Step 3: Create map scene and implement map renderer**

```tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/observe/battle_map_view.gd" id="1"]

[node name="BattleMapView" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")
```

```gdscript
extends Control

var _snapshot: Array = []


func set_snapshot(snapshot: Array) -> void:
	_snapshot = snapshot.duplicate(true)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111821"), true)
	draw_rect(Rect2(Vector2(120, 120), size - Vector2(240, 240)), Color("#1E2A36"), false, 2.0)
	for row in _snapshot:
		var pos := row.get("position", Vector2.ZERO)
		if pos is Vector2:
			draw_circle(pos, 3.0, Color("#4C5C68"))
```

- [ ] **Step 4: Integrate map view and richer log text into observe screen**

```gdscript
const BATTLE_MAP_SCENE := preload("res://scenes/observe/battle_map_view.tscn")
var _battle_map: Control


func _ensure_map() -> void:
	if _battle_map != null:
		return
	_battle_map = BATTLE_MAP_SCENE.instantiate()
	_battle_map.name = "BattleMap"
	add_child(_battle_map)
	_battle_map.move_to_front()


func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = frame.get("entities", []).duplicate(true)
	var snapshot := build_token_snapshot()
	sync_token_views(snapshot)
	_ensure_map()
	_battle_map.call("set_snapshot", snapshot)
	update_hud_for_tick(_current_tick, _event_rows)
```

- [ ] **Step 5: Re-run observe map smoke and existing observe tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_map_view_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_layer_hud_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_token_render_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/observe/battle_map_view.tscn scripts/observe/battle_map_view.gd scripts/observe/observe_screen.gd tests/observe_map_view_smoke_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add observe battle map and readable feed"
```

## Task 4: Build Visible 结果结算 Report UI

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/result/result_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_screen_ui_smoke_test.gd`

- [ ] **Step 1: Write a failing result UI smoke test**

```gdscript
extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	SessionState.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": ["ally_hound_remnant"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}]
	}
	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("Layout/HeadlineLabel") != null)
	assert(screen.get_node_or_null("Layout/ReturnButton") != null)
	assert(not (screen.get_node("Layout/HeadlineLabel") as Label).text.is_empty())
	screen.queue_free()
	await process_frame
	quit(0)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_ui_smoke_test.gd`  
Expected: FAIL because result scene does not include named UI nodes yet

- [ ] **Step 3: Add result scene report layout**

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

[node name="Layout" type="VBoxContainer" parent="."]
layout_mode = 2
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 48.0
offset_top = 40.0
offset_right = -48.0
offset_bottom = -40.0
theme_override_constants/separation = 10

[node name="HeadlineLabel" type="Label" parent="Layout"]
layout_mode = 2
text = "结果"

[node name="SurvivorLabel" type="Label" parent="Layout"]
layout_mode = 2
text = ""

[node name="CasualtyLabel" type="Label" parent="Layout"]
layout_mode = 2
text = ""

[node name="EventLabel" type="Label" parent="Layout"]
layout_mode = 2
text = ""
autowrap_mode = 2

[node name="StrategyLabel" type="Label" parent="Layout"]
layout_mode = 2
text = ""
autowrap_mode = 2

[node name="ReturnButton" type="Button" parent="Layout"]
layout_mode = 2
text = "返回出战前准备"
```

- [ ] **Step 4: Bind summary into result labels and wire return button**

```gdscript
@onready var _headline: Label = $Layout/HeadlineLabel
@onready var _survivor: Label = $Layout/SurvivorLabel
@onready var _casualty: Label = $Layout/CasualtyLabel
@onready var _event: Label = $Layout/EventLabel
@onready var _strategy: Label = $Layout/StrategyLabel
@onready var _return_button: Button = $Layout/ReturnButton


func _ready() -> void:
	var summary := build_summary(SessionState.last_battle_result)
	_headline.text = String(summary.get("headline", "结果"))
	_survivor.text = "存活: %s" % ", ".join(summary.get("survivor_lines", []))
	_casualty.text = "阵亡: %s" % ", ".join(summary.get("casualty_lines", []))
	_event.text = "事件: %s" % ", ".join(summary.get("event_lines", []))
	_strategy.text = "策略: %s" % ", ".join(summary.get("strategy_lines", []))
	_return_button.pressed.connect(return_to_preparation)
```

- [ ] **Step 5: Re-run result UI smoke and summary tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_ui_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_summary_fields_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/result/result_screen.tscn scripts/result/result_screen.gd tests/result_screen_ui_smoke_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add visible result report layout"
```

## Task 5: Strengthen Full-Loop Smoke And Refresh Handoff

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/app_flow_smoke_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [ ] **Step 1: Extend app flow smoke with visible-screen assertions**

```gdscript
# in tests/app_flow_smoke_test.gd, after each transition
assert(prep_screen.get_node_or_null("Layout/StartBattleButton") != null)
...
assert(result_screen.get_node_or_null("Layout/ReturnButton") != null)
```

- [ ] **Step 2: Run app flow smoke and confirm expected failure first**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`  
Expected: FAIL before Task 1/Task 4 complete because named UI nodes are missing

- [ ] **Step 3: Keep test green after Task 1-4 by aligning node names**

```gdscript
# maintain PreparationScreen and ResultScreen node names
assert(prep_again.name == "PreparationScreen")
assert(result_screen.name == "ResultScreen")
```

- [ ] **Step 4: Run full regression bundle**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_screen_ui_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_start_battle_ui_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_map_view_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_ui_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`  
Expected: PASS

- [ ] **Step 5: Refresh handoff status for the new phase**

```md
## 当前状态
- phase2 runtime hardening: completed
- phase3 observe readability: completed
- phase4 UI productization: ready to execute from new plan

## 明天最建议先做什么
直接从 `docs/superpowers/plans/2026-03-30-godlingbattle-phase4-ui-productization.md` 的 Task 1 开始。
```

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add tests/app_flow_smoke_test.gd docs/HANDOFF.md
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "docs: prepare handoff for phase4 ui productization"
```

## Self-Review

Spec coverage:
- preparation screen should feel like formal product screen: Task 1 + Task 2
- observe should keep readable positions/hp/event/strategy cues: Task 3
- result screen should show report fields and return action: Task 4
- full loop should remain stable and testable: Task 5

Placeholder scan:
- no `TODO`/`TBD` placeholders
- every task includes concrete file paths, code snippets, commands, and expected outcomes

Type consistency:
- `battle_setup` keys remain: `hero_id`, `ally_ids`, `strategy_ids`, `battle_id`, `seed`
- timeline frame keys remain: `tick`, `entities`
- `battle_result` summary keys remain: `victory`, `survivors`, `casualties`, `triggered_events`, `triggered_strategies`, `log_entries`
