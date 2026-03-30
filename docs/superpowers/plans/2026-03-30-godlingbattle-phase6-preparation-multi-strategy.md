# GodlingBattle Phase 6 Preparation Multi-Strategy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade `出战前准备` from single-strategy toggle to a scalable multi-strategy selection component while preserving existing `battle_setup` contract and budget validation behavior.

**Architecture:** Keep runtime and result flow unchanged. Replace single `StrategySelect` checkbox with a dynamic strategy list container in preparation UI. `preparation_screen.gd` will build strategy options from `battle_content`, sync selected states both ways, and continue outputting normalized `strategy_ids` in `battle_setup`.

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests, deterministic runtime

---

## File Structure

Core files for this phase task:

- `scenes/prep/preparation_screen.tscn`: replace single strategy checkbox with strategy list container
- `scripts/prep/preparation_screen.gd`: dynamic strategy options, selection sync, budget projection
- `tests/preparation_controls_smoke_test.gd`: verify strategy list container exists
- `tests/preparation_multi_strategy_selection_test.gd`: verify multi-selection reflects into `battle_setup` and budget label
- `tests/preparation_strategy_budget_test.gd`: keep over-budget guard behavior under multi-select setup
- `docs/HANDOFF.md`: update global status after task is done

## Task 1: Replace Single Strategy Toggle With Dynamic Strategy List

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/prep/preparation_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/prep/preparation_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_controls_smoke_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_multi_strategy_selection_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/preparation_strategy_budget_test.gd`

- [ ] **Step 1: Write failing tests for new strategy list structure and behavior**

```gdscript
# tests/preparation_controls_smoke_test.gd
_expect_node(screen, "Layout/StrategyList")
```

```gdscript
# tests/preparation_multi_strategy_selection_test.gd
var first_checkbox := screen.get_node_or_null("Layout/StrategyList/Strategy_strat_void_echo")
var second_checkbox := screen.get_node_or_null("Layout/StrategyList/Strategy_strat_chill_wave")
assert(first_checkbox != null)
assert(second_checkbox != null)
```

- [ ] **Step 2: Run tests and confirm RED**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: FAIL because `StrategyList` does not exist yet

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_multi_strategy_selection_test.gd`  
Expected: FAIL because dynamic strategy checkboxes do not exist yet

- [ ] **Step 3: Implement minimal dynamic strategy list in scene and script**

```tscn
[node name="StrategyList" type="VBoxContainer" parent="Layout"]
layout_mode = 2
theme_override_constants/separation = 8
```

```gdscript
@onready var strategy_list: VBoxContainer = $Layout/StrategyList
var _strategy_checkboxes: Dictionary = {}

func _bind_content_options() -> void:
	# existing hero/battle bindings...
	_rebuild_strategy_options(content)

func _rebuild_strategy_options(content: Node) -> void:
	for child in strategy_list.get_children():
		child.queue_free()
	_strategy_checkboxes.clear()
	for strategy_id in content.get_all_strategy_ids():
		var strategy: Dictionary = content.get_strategy(strategy_id)
		var checkbox := CheckBox.new()
		checkbox.name = "Strategy_%s" % strategy_id
		checkbox.text = "携带：%s（%d）" % [String(strategy.get("name", strategy_id)), int(strategy.get("cost", 0))]
		checkbox.toggled.connect(_on_strategy_toggled)
		strategy_list.add_child(checkbox)
		_strategy_checkboxes[strategy_id] = checkbox
```

- [ ] **Step 4: Re-run tests and confirm GREEN**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_controls_smoke_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_multi_strategy_selection_test.gd`  
Expected: PASS

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/preparation_strategy_budget_test.gd`  
Expected: PASS with budget disable behavior unchanged

- [ ] **Step 5: Expand verification and update handoff**

Run key path smoke:  
`/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/app_flow_smoke_test.gd`

Run full regression:  
`for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`

Update only global progress in `docs/HANDOFF.md` (document uniqueness rule).

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scenes/prep/preparation_screen.tscn scripts/prep/preparation_screen.gd tests/preparation_controls_smoke_test.gd tests/preparation_multi_strategy_selection_test.gd tests/preparation_strategy_budget_test.gd docs/HANDOFF.md docs/superpowers/plans/2026-03-30-godlingbattle-phase6-preparation-multi-strategy.md
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: support multi-strategy selection in preparation screen"
```
