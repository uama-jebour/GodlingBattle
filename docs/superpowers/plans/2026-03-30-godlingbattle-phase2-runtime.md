# GodlingBattle Phase 2 Runtime Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the current playable skeleton into a stable V1 runtime loop where setup/content drive battle simulation, observe consumes timeline, and result displays structured report fields.

**Architecture:** Keep the existing `Data -> Preparation -> Runtime -> Observe -> Result` boundaries. Strengthen contracts between layers (`battle_setup`, runtime state, timeline frame, `battle_result`) before adding any new content breadth. Enforce TDD for each behavior upgrade.

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests, deterministic seed runtime

---

## File Structure

Core files for this phase:

- `autoload/battle_content.gd`: fill missing strategy/unit defs referenced by test packs
- `scripts/battle_runtime/battle_state.gd`: runtime state shape from setup/content
- `scripts/battle_runtime/battle_ai_system.gd`: per-entity action selection (melee/ranged)
- `scripts/battle_runtime/battle_combat_system.gd`: damage/cooldown resolution and casualty tracking
- `scripts/battle_runtime/battle_event_response_system.gd`: staged event flow (`warning -> response -> resolve`)
- `scripts/battle_runtime/battle_runner.gd`: full run loop and structured `battle_result`
- `scripts/observe/observe_screen.gd`: timeline playback and transition timing
- `scripts/observe/token_view.gd`: token data projection (`entity_id`, name, hp ratio)
- `scripts/result/result_screen.gd`: structured result summary mapping
- `tools/export_test_packs.gd`: run packs and export runtime rows
- `tests/content_consistency_test.gd`: test-pack/content id consistency
- `tests/runtime_setup_integration_test.gd`: setup-driven spawn and result fields
- `tests/runtime_event_stage_test.gd`: event warning/response/resolve checks
- `tests/observe_timeline_test.gd`: observe timeline consumption behavior
- `tests/result_summary_fields_test.gd`: result summary field coverage
- `tests/test_pack_runner_export_test.gd`: pack-run + CSV row schema smoke test

## Task 1: Align Content IDs With Test Packs

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/autoload/battle_content.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/content_consistency_test.gd`

- [ ] **Step 1: Write a failing content consistency test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var missing: Array[String] = []
	for pack in BattleContent.get_test_packs():
		for strategy_id in pack.get("strategy_ids", []):
			if BattleContent.get_strategy(String(strategy_id)).is_empty():
				missing.append("missing strategy: %s" % strategy_id)
	if missing.is_empty():
		quit(0)
	for m in missing:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/content_consistency_test.gd`  
Expected: FAIL with missing `strat_chill_wave`, `strat_counter_demon_summon`, `strat_nuclear_strike`

- [ ] **Step 3: Add missing strategy definitions**

```gdscript
"strat_chill_wave": TYPES.strategy({
	"strategy_id": "strat_chill_wave",
	"name": "寒潮冲击",
	"kind": "active",
	"cost": 3,
	"cooldown": 8.0,
	"tags": ["寒霜"],
	"trigger_def": {"type": "cooldown"},
	"effect_def": {"type": "enemy_group_slow", "ratio": 0.35, "duration": 3.0}
})
```

- [ ] **Step 4: Re-run consistency test**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/content_consistency_test.gd`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add autoload/battle_content.gd tests/content_consistency_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: align test pack strategy ids"
```

## Task 2: Make Runtime Spawn From Setup + Content

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_state.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_runner.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_setup_integration_test.gd`

- [ ] **Step 1: Write failing setup-integration test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 42
	})
	var result: Dictionary = payload.get("result", {})
	assert(result.has("status"))
	assert(result.has("casualties"))
	assert(result.has("triggered_events"))
	assert(result.has("triggered_strategies"))
	quit(0)
```

- [ ] **Step 2: Run it to confirm fail**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/runtime_setup_integration_test.gd`  
Expected: FAIL because current `result` lacks full schema

- [ ] **Step 3: Expand state init and result schema**

```gdscript
return {
	"setup": setup.duplicate(true),
	"seed": int(setup.get("seed", 0)),
	"rng": RandomNumberGenerator.new(),
	"entities": _spawn_entities_from_setup(setup),
	"elapsed_ticks": 0,
	"max_ticks": MAX_SECONDS * TICK_RATE,
	"tick_rate": TICK_RATE,
	"log_entries": [],
	"triggered_events": [],
	"triggered_strategies": [],
	"casualties": [],
	"completed": false
}
```

- [ ] **Step 4: Return explicit runtime status**

```gdscript
"result": {
	"status": "completed",
	"victory": victory,
	"defeat_reason": defeat_reason,
	"elapsed_seconds": elapsed,
	"survivors": survivors,
	"casualties": casualties,
	"triggered_events": triggered_events,
	"triggered_strategies": triggered_strategies,
	"log_entries": logs
}
```

- [ ] **Step 5: Re-run integration test**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/runtime_setup_integration_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/battle_runtime/battle_state.gd scripts/battle_runtime/battle_runner.gd tests/runtime_setup_integration_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: make runtime setup-driven with full result schema"
```

## Task 3: Implement Staged Event Warning/Response/Resolve

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_event_response_system.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_runner.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_event_stage_test.gd`

- [ ] **Step 1: Write failing staged-event test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 77
	})
	var logs: Array = payload.get("result", {}).get("log_entries", [])
	var has_warning := false
	var has_resolve := false
	for row in logs:
		if row.get("type", "") == "event_warning":
			has_warning = true
		if row.get("type", "") == "event_resolve":
			has_resolve = true
	assert(has_warning)
	assert(has_resolve)
	quit(0)
```

- [ ] **Step 2: Run to verify fail**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/runtime_event_stage_test.gd`  
Expected: FAIL because resolve-stage logs are missing

- [ ] **Step 3: Add staged event state machine**

```gdscript
# idle -> warning -> response -> resolve
if _should_warn(event, state):
	_push_log(state, "event_warning", event_id)
elif _should_resolve(event, state):
	var responded := _check_response(event, state)
	_push_log(state, "event_resolve", event_id, {"responded": responded})
	if not responded:
		_apply_unresolved_effect(event, state)
```

- [ ] **Step 4: Track `triggered_events` in result**

```gdscript
state["triggered_events"].append({
	"event_id": event_id,
	"responded": responded,
	"tick": tick
})
```

- [ ] **Step 5: Re-run staged-event test**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/runtime_event_stage_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/battle_runtime/battle_event_response_system.gd scripts/battle_runtime/battle_runner.gd tests/runtime_event_stage_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add staged event warning-response-resolve flow"
```

## Task 4: Make Observe Consume Timeline Instead Of Immediate Jump

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/token_view.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_timeline_test.gd`

- [ ] **Step 1: Write failing observe timeline test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	assert(screen.has_method("apply_timeline_frame"))
	assert(screen.has_method("build_token_snapshot"))
	screen.free()
	quit(0)
```

- [ ] **Step 2: Run to verify fail**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_timeline_test.gd`  
Expected: FAIL because helper methods do not exist yet

- [ ] **Step 3: Add timeline frame application helpers**

```gdscript
func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = frame.get("entities", []).duplicate(true)


func build_token_snapshot() -> Array:
	var rows: Array = []
	for e in _current_entities:
		rows.append({
			"entity_id": String(e.get("entity_id", "")),
			"hp_ratio": float(e.get("hp", 0.0)) / max(float(e.get("max_hp", 1.0)), 1.0)
		})
	return rows
```

- [ ] **Step 4: Keep transition to result at playback end**

```gdscript
if _frame_index >= SessionState.last_timeline.size():
	AppRouter.goto_result()
```

- [ ] **Step 5: Re-run observe timeline test**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/observe_timeline_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/observe/observe_screen.gd scripts/observe/token_view.gd tests/observe_timeline_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: add timeline-driven observe playback helpers"
```

## Task 5: Upgrade Result Summary + Test Pack Runner Export

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/export_test_packs.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_summary_fields_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/test_pack_runner_export_test.gd`

- [ ] **Step 1: Add failing result summary field test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/result/result_screen.gd").new()
	var summary: Dictionary = screen.build_summary({
		"victory": false,
		"defeat_reason": "hero_dead",
		"survivors": ["hero_1"],
		"casualties": ["ally_1"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}],
		"log_entries": []
	})
	assert(summary.has("casualty_lines"))
	assert(summary.has("strategy_lines"))
	screen.free()
	quit(0)
```

- [ ] **Step 2: Add failing pack runner export test**

```gdscript
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter: RefCounted = load("res://tools/export_test_packs.gd").new()
	var rows: Array = exporter.run_test_packs([{
		"pack_id": "pack_void_echo",
		"battle_id": "battle_void_gate_alpha",
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"]
	}])
	assert(rows.size() == 1)
	assert(rows[0].has("pack_id"))
	assert(rows[0].has("victory"))
	assert(rows[0].has("elapsed_seconds"))
	quit(0)
```

- [ ] **Step 3: Implement summary field mapping**

```gdscript
"casualty_lines": result.get("casualties", []).duplicate(),
"event_lines": _map_ids(result.get("triggered_events", []), "event_id"),
"strategy_lines": _map_ids(result.get("triggered_strategies", []), "strategy_id")
```

- [ ] **Step 4: Implement `run_test_packs` in exporter**

```gdscript
func run_test_packs(packs: Array) -> Array:
	var runner := load("res://scripts/battle_runtime/battle_runner.gd").new()
	var rows: Array = []
	for pack in packs:
		var payload: Dictionary = runner.run(pack)
		var result: Dictionary = payload.get("result", {})
		rows.append({
			"pack_id": String(pack.get("pack_id", "")),
			"battle_id": String(pack.get("battle_id", "")),
			"victory": bool(result.get("victory", false)),
			"elapsed_seconds": float(result.get("elapsed_seconds", 0.0))
		})
	return rows
```

- [ ] **Step 5: Re-run both tests**

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/result_summary_fields_test.gd`  
Expected: PASS

Run: `godot --headless --path /Users/zhangwei/Documents/Mycode/GodlingBattle --script res://tests/test_pack_runner_export_test.gd`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle add scripts/result/result_screen.gd tools/export_test_packs.gd tests/result_summary_fields_test.gd tests/test_pack_runner_export_test.gd
git -C /Users/zhangwei/Documents/Mycode/GodlingBattle commit -m "feat: enrich result summary and pack-run exporter"
```

## Self-Review

Spec coverage:
- runtime uses setup/content: covered by Task 2
- staged event behavior: covered by Task 3
- observe playback contract: covered by Task 4
- result structured report and pack tooling: covered by Task 5
- content/test-pack ID consistency: covered by Task 1

Ambiguity scan:
- all tasks use concrete file paths
- each implementation task includes concrete code snippets
- each verification step includes executable command + expected result

Type consistency:
- keep `battle_setup` fields: `hero_id`, `ally_ids`, `strategy_ids`, `battle_id`, `seed`
- keep `battle_result` fields: `status`, `victory`, `defeat_reason`, `elapsed_seconds`, `survivors`, `casualties`, `triggered_events`, `triggered_strategies`, `log_entries`
- observe reads timeline frames with `tick` and `entities`
