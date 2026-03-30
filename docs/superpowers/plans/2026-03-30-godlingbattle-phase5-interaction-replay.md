# GodlingBattle Phase 5 Interaction And Replay Implementation Plan

> Status (2026-03-30): completed and merged into `main` (`a8d75ae`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Upgrade the current visible loop into an actually operable game loop by adding interactive preparation controls, observe playback controls, and result-page replay action while preserving deterministic runtime behavior.

**Architecture:** Keep runtime/data contracts unchanged (`battle_setup`, timeline frames, `battle_result`) and only extend UI controller scripts around those contracts. Preparation becomes content-driven interactive input, observe gains transport controls on top of timeline playback, and result gains replay navigation using existing session state.

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests, deterministic tick runtime

---

## File Structure

Core files for this phase:

- `scenes/prep/preparation_screen.tscn`: add interactive input nodes (hero/battle/strategy/seed/budget)
- `scripts/prep/preparation_screen.gd`: load content options, bind UI inputs, emit normalized `battle_setup`
- `tests/preparation_controls_smoke_test.gd`: verify preparation input controls exist and initialize
- `tests/preparation_strategy_budget_test.gd`: verify over-budget setup is blocked in UI
- `scenes/observe/observe_screen.tscn`: add playback controls panel
- `scripts/observe/observe_screen.gd`: pause/resume and speed multiplier controls
- `tests/observe_playback_controls_test.gd`: verify observe controls and playback gating
- `scenes/result/result_screen.tscn`: add replay button
- `scripts/result/result_screen.gd`: replay last setup flow
- `tests/result_replay_flow_test.gd`: verify replay transitions to observe with preserved setup
- `tests/app_flow_smoke_test.gd`: verify interactive flow + replay branch
- `docs/HANDOFF.md`: refresh to phase5 execution baseline

## Task 1: Add Interactive 出战前准备 Controls

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/prep/preparation_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_controls_smoke_test.gd`

- [x] **Step 1: Write a failing preparation controls smoke test**

```gdscript
extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("Layout/HeroSelect") != null)
	assert(screen.get_node_or_null("Layout/BattleSelect") != null)
	assert(screen.get_node_or_null("Layout/SeedInput") != null)
	assert(screen.get_node_or_null("Layout/StrategySelect") != null)
	screen.queue_free()
	await process_frame
	quit(0)
```

- [x] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: FAIL because interactive nodes do not exist yet

- [x] **Step 3: Add preparation input nodes to scene**

```tscn
[node name="HeroSelect" type="OptionButton" parent="Layout"]
layout_mode = 2

[node name="BattleSelect" type="OptionButton" parent="Layout"]
layout_mode = 2

[node name="SeedInput" type="SpinBox" parent="Layout"]
layout_mode = 2
min_value = 1.0
max_value = 999999.0
value = 1001.0

[node name="StrategySelect" type="CheckBox" parent="Layout"]
layout_mode = 2
text = "携带：虚无回响"
button_pressed = true

[node name="BudgetLabel" type="Label" parent="Layout"]
layout_mode = 2
text = "预算: 0 / 16"
```

- [x] **Step 4: Bind inputs and content options in preparation script**

```gdscript
@onready var hero_select: OptionButton = $Layout/HeroSelect
@onready var battle_select: OptionButton = $Layout/BattleSelect
@onready var seed_input: SpinBox = $Layout/SeedInput
@onready var strategy_select: CheckBox = $Layout/StrategySelect
@onready var budget_label: Label = $Layout/BudgetLabel


func _ready() -> void:
	_bind_content_options()
	_bind_control_events()
	_apply_selection_to_controls()
	_render_shell()


func _bind_content_options() -> void:
	hero_select.clear()
	hero_select.add_item("英雄：天使", 0)
	hero_select.set_item_metadata(0, "hero_angel")
	battle_select.clear()
	battle_select.add_item("虚无裂隙·一层", 0)
	battle_select.set_item_metadata(0, "battle_void_gate_alpha")


func _bind_control_events() -> void:
	hero_select.item_selected.connect(_on_control_changed)
	battle_select.item_selected.connect(_on_control_changed)
	seed_input.value_changed.connect(_on_seed_changed)
	strategy_select.toggled.connect(_on_strategy_toggled)


func _on_control_changed(_index: int) -> void:
	_pull_selection_from_controls()
	_render_shell()
```

- [x] **Step 5: Re-run preparation controls smoke test**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: PASS

- [x] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/prep/preparation_screen.tscn scripts/prep/preparation_screen.gd tests/preparation_controls_smoke_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add interactive preparation controls"
```

## Task 2: Enforce Strategy Budget In UI State

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_strategy_budget_test.gd`

- [x] **Step 1: Write a failing strategy-budget UI test**

```gdscript
extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("set_selection", {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_nuclear_strike", "strat_nuclear_strike", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	await process_frame
	var start_btn := screen.get_node("Layout/StartBattleButton") as Button
	assert(start_btn.disabled)
	screen.queue_free()
	await process_frame
	quit(0)
```

- [x] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_strategy_budget_test.gd`  
Expected: FAIL before budget label/disable logic is synced with controls

- [x] **Step 3: Add budget projection and disable reasons to shell renderer**

```gdscript
func _render_shell() -> void:
	var current_selection := _current_selection.duplicate(true)
	var setup := build_battle_setup(current_selection)
	budget_label.text = "预算: %d / %d" % [_strategy_total_cost(current_selection), DEFAULT_STRATEGY_BUDGET]
	selection_summary.text = _format_selection_summary(current_selection)
	if setup.has("invalid_reason"):
		var reason := _describe_invalid_reason(String(setup.get("invalid_reason", "")))
		battle_summary.text = "战斗信息\n%s" % reason
		error_label.text = reason
		start_battle_button.disabled = true
		return
	battle_summary.text = _format_battle_summary(setup)
	error_label.text = ""
	start_battle_button.disabled = false


func _strategy_total_cost(selection: Dictionary) -> int:
	var content: Node = BATTLE_CONTENT.new()
	var total := 0
	for strategy_id in selection.get("strategy_ids", []):
		total += int(content.get_strategy(String(strategy_id)).get("cost", 0))
	content.free()
	return total
```

- [x] **Step 4: Re-run budget test and preparation UI smoke tests**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_strategy_budget_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: PASS

- [x] **Step 5: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/prep/preparation_screen.gd tests/preparation_strategy_budget_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: enforce strategy budget in preparation ui"
```

## Task 3: Add Observe Playback Controls

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_controls_test.gd`

- [x] **Step 1: Write a failing observe playback control test**

```gdscript
extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{"tick": 0, "entities": []}, {"tick": 1, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}
	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("PlaybackPanel/PauseButton") != null)
	assert(screen.get_node_or_null("PlaybackPanel/SpeedSelect") != null)
	screen.queue_free()
	await process_frame
	quit(0)
```

- [x] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_playback_controls_test.gd`  
Expected: FAIL because playback control nodes do not exist yet

- [x] **Step 3: Add observe playback control nodes**

```tscn
[node name="PlaybackPanel" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_right = 1.0
offset_left = 20.0
offset_top = 84.0
offset_right = -20.0
offset_bottom = 120.0

[node name="PauseButton" type="Button" parent="PlaybackPanel"]
layout_mode = 2
text = "暂停"

[node name="SpeedSelect" type="OptionButton" parent="PlaybackPanel"]
layout_mode = 2
```

- [x] **Step 4: Implement pause/speed behavior in observe script**

```gdscript
@onready var _pause_button: Button = $PlaybackPanel/PauseButton
@onready var _speed_select: OptionButton = $PlaybackPanel/SpeedSelect
var _playback_speed := 1.0
var _paused := false


func _ready() -> void:
	_setup_playback_controls()
	# existing init...


func _setup_playback_controls() -> void:
	_speed_select.clear()
	_speed_select.add_item("x1", 0)
	_speed_select.add_item("x2", 1)
	_speed_select.set_item_metadata(0, 1.0)
	_speed_select.set_item_metadata(1, 2.0)
	_pause_button.pressed.connect(_toggle_pause)
	_speed_select.item_selected.connect(_on_speed_selected)


func _process(delta: float) -> void:
	if _paused:
		return
	_playback_accumulator += delta * _playback_speed
	# existing playback logic...
```

- [x] **Step 5: Re-run playback control and observe regressions**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_playback_controls_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_map_view_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_layer_hud_test.gd`  
Expected: PASS

- [x] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/observe/observe_screen.tscn scripts/observe/observe_screen.gd tests/observe_playback_controls_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add observe playback controls"
```

## Task 4: Add Result Replay Action

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/result/result_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_replay_flow_test.gd`

- [x] **Step 1: Write a failing result replay flow test**

```gdscript
extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_battle_result = {"victory": true, "survivors": ["hero_angel"], "casualties": [], "triggered_events": [], "triggered_strategies": []}
	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	assert(screen.get_node_or_null("Layout/ReplayButton") != null)
	screen.queue_free()
	await process_frame
	quit(0)
```

- [x] **Step 2: Run it to confirm fail**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_replay_flow_test.gd`  
Expected: FAIL because replay button does not exist yet

- [x] **Step 3: Add replay button and implement replay flow**

```tscn
[node name="ReplayButton" type="Button" parent="Layout"]
layout_mode = 2
text = "再战一场"
```

```gdscript
@onready var _replay_button: Button = $Layout/ReplayButton


func _ready() -> void:
	# existing summary bind...
	_replay_button.pressed.connect(replay_last_setup)


func replay_last_setup() -> void:
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
		return
	session_state.clear_runtime()
	var app_router := _app_router()
	if app_router != null:
		app_router.goto_observe()
```

- [x] **Step 4: Re-run replay and result regressions**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_replay_flow_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_ui_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_screen_test.gd`  
Expected: PASS

- [x] **Step 5: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/result/result_screen.tscn scripts/result/result_screen.gd tests/result_replay_flow_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add result replay action"
```

## Task 5: Refresh Full Flow Smoke And Handoff For Phase 5

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/app_flow_smoke_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [x] **Step 1: Extend app flow smoke with replay branch**

```gdscript
# after reaching result screen
assert(result_screen.get_node_or_null("Layout/ReplayButton") != null)
result_screen.replay_last_setup()
await process_frame
var observe_again := _current_screen(screen_host)
assert(observe_again != null)
assert(observe_again.name == "ObserveScreen")
```

- [x] **Step 2: Run app flow smoke to verify pass**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`  
Expected: PASS

- [x] **Step 3: Run focused phase5 regression bundle**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_strategy_budget_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_playback_controls_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_replay_flow_test.gd`  
Expected: PASS

- [x] **Step 4: Update handoff to phase5 baseline**

```md
## 当前状态
- phase4 ui productization: completed
- phase5 interaction & replay: in progress

## 明天最建议先做什么
直接从 `docs/superpowers/plans/2026-03-30-godlingbattle-phase5-interaction-replay.md` 的当前未完成 Task 开始。
```

- [x] **Step 5: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add tests/app_flow_smoke_test.gd docs/HANDOFF.md
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "docs: refresh handoff for phase5 interaction"
```

## Execution Result (2026-03-30)

- All tasks in this plan were completed and merged to `main`.
- Final merge commit: `a8d75ae`.
- Full regression run: `tests/*.gd` => `30/30` pass.

## Self-Review

Spec coverage:
- preparation becomes operable input surface: Task 1 + Task 2
- observe gains controllable playback: Task 3
- result gains replay action: Task 4
- full loop and handoff updated: Task 5

Placeholder scan:
- no `TODO`/`TBD` placeholders
- all tasks include concrete file paths, snippets, commands, and expected outcomes

Type consistency:
- `battle_setup` fields remain: `hero_id`, `ally_ids`, `strategy_ids`, `battle_id`, `seed`
- timeline frame fields remain: `tick`, `entities`
- `battle_result` fields remain: `victory`, `survivors`, `casualties`, `triggered_events`, `triggered_strategies`, `log_entries`
