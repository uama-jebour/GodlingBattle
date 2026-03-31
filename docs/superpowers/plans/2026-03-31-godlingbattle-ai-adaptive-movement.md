# GodlingBattle Adaptive AI Movement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement deterministic adaptive AI movement so units can seek/avoid/breakout based on combat context, stay in battlefield bounds, and move smoothly without teleport artifacts.

**Architecture:** Keep combat resolution deterministic in `battle_ai_system.gd` with four layers: context builder, action scoring, blended action selection with hysteresis, and bounded motion integrator. Runtime position remains source of truth; Observe adds view-only interpolation in `token_view.gd` to eliminate visual jumps. Add focused runtime/observe tests to gate no-teleport, boundary, engagement reachability, and breakout response.

**Tech Stack:** Godot 4.x, GDScript, existing headless test scripts in `tests/*.gd`.

---

## File Structure

### Runtime AI core
- Modify: `scripts/battle_runtime/battle_ai_system.gd`
- Responsibility: Context extraction, action scoring (`approach/kite/breakout/flank`), action blending, velocity/acceleration limits, boundary clamp.

### Observe motion presentation
- Modify: `scripts/observe/token_view.gd`
- Responsibility: Visual-only interpolation from previous display position to latest runtime position, with snap guard for large deltas.

### Runtime behavior tests
- Create: `tests/runtime_ai_no_teleport_test.gd`
- Create: `tests/runtime_ai_boundary_clamp_test.gd`
- Create: `tests/runtime_ai_engage_reachability_test.gd`
- Create: `tests/runtime_ai_breakout_response_test.gd`
- Responsibility: enforce deterministic behavior contracts for movement continuity, bounds, reachability, and breakout.

### Observe smoothing test
- Create: `tests/observe_motion_smoothing_visual_test.gd`
- Responsibility: ensure interpolation updates token position continuously and converges.

### Existing regression tests to keep green
- Run: `tests/runtime_determinism_test.gd`
- Run: `tests/runtime_engagement_pacing_test.gd`
- Run: `tests/runtime_parallel_attack_same_tick_test.gd`
- Run: `tests/observe_token_render_test.gd`
- Run: `tests/observe_battlefield_playable_area_test.gd`

---

### Task 1: Build Context + Action Scoring in Runtime AI

**Files:**
- Modify: `scripts/battle_runtime/battle_ai_system.gd`
- Create: `tests/runtime_ai_engage_reachability_test.gd`

- [ ] **Step 1: Write the failing reachability test**

```gdscript
extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = RUNNER.new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	var timeline: Array = payload.get("timeline", [])
	var min_distance := INF
	for frame in timeline:
		var entities: Array = (frame as Dictionary).get("entities", [])
		for a in entities:
			if not bool(a.get("alive", false)) or str(a.get("side", "")) == "enemy":
				continue
			for b in entities:
				if not bool(b.get("alive", false)) or str(b.get("side", "")) != "enemy":
					continue
				min_distance = minf(min_distance, (a.get("position", Vector2.ZERO) as Vector2).distance_to(b.get("position", Vector2.ZERO) as Vector2))
	if min_distance > 78.0:
		_failures.append("expected practical engagement distance, got %f" % min_distance)
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails on old behavior**

Run: ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_engage_reachability_test.gd`
Expected: FAIL when units cannot reliably enter practical engagement distance.

- [ ] **Step 3: Add context + score functions in AI system**

```gdscript
func _build_context(entity: Dictionary, target: Dictionary, entities: Array) -> Dictionary:
	var distance := _position_of(entity).distance_to(_position_of(target))
	var attack_range := maxf(float(entity.get("attack_range", 0.0)), 0.0)
	var target_range := maxf(float(target.get("attack_range", 0.0)), 0.0)
	return {
		"distance": distance,
		"attack_range": attack_range,
		"range_advantage": attack_range - target_range,
		"local_outnumbered": _local_outnumbered(entity, entities),
		"pressure": float(entity.get("recent_damage_pressure", 0.0)),
		"hp_ratio": _hp_ratio(entity),
		"boundary_risk": _boundary_risk(_position_of(entity))
	}

func _score_actions(context: Dictionary) -> Dictionary:
	var distance := float(context.get("distance", 0.0))
	var attack_range := maxf(float(context.get("attack_range", 0.0)), 1.0)
	var range_adv := float(context.get("range_advantage", 0.0))
	var pressure := float(context.get("pressure", 0.0))
	var outnumbered := float(context.get("local_outnumbered", 0.0))
	var hp_ratio := float(context.get("hp_ratio", 1.0))
	var boundary_risk := float(context.get("boundary_risk", 0.0))
	return {
		"approach": (distance / attack_range) * 0.9 - pressure * 0.4 - maxf(0.0, outnumbered) * 0.3,
		"kite": maxf(0.0, range_adv) * 0.6 + pressure * 0.6 - (distance / attack_range) * 0.2,
		"breakout": pressure * 0.8 + maxf(0.0, outnumbered) * 0.7 + (1.0 - hp_ratio) * 0.6,
		"flank": clampf(1.2 - absf(distance - attack_range) / attack_range, 0.0, 1.2) * (1.0 - boundary_risk)
	}
```

- [ ] **Step 4: Wire scoring entrypoint without changing final integrator yet**

```gdscript
var context := _build_context(entity, target, entities)
var scores := _score_actions(context)
var steering := _select_blended_direction(entity, target, context, scores)
```

- [ ] **Step 5: Run test to verify it passes**

Run: ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_engage_reachability_test.gd`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/battle_runtime/battle_ai_system.gd tests/runtime_ai_engage_reachability_test.gd
git commit -m "feat: add adaptive ai context scoring for engagement reachability"
```

---

### Task 2: Add Blended Steering + Boundary + No-Teleport Runtime Guards

**Files:**
- Modify: `scripts/battle_runtime/battle_ai_system.gd`
- Create: `tests/runtime_ai_no_teleport_test.gd`
- Create: `tests/runtime_ai_boundary_clamp_test.gd`

- [ ] **Step 1: Write failing no-teleport test**

```gdscript
extends SceneTree
const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = RUNNER.new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	var timeline: Array = payload.get("timeline", [])
	for i in range(1, timeline.size()):
		var prev_by_id := {}
		for row in (timeline[i - 1] as Dictionary).get("entities", []):
			prev_by_id[str(row.get("entity_id", ""))] = row.get("position", Vector2.ZERO)
		for row in (timeline[i] as Dictionary).get("entities", []):
			var id := str(row.get("entity_id", ""))
			if not prev_by_id.has(id):
				continue
			var d := (row.get("position", Vector2.ZERO) as Vector2).distance_to(prev_by_id[id] as Vector2)
			if d > 18.0:
				_failures.append("teleport-like movement for %s: %f" % [id, d])
				break
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Write failing boundary clamp test**

```gdscript
extends SceneTree
const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
var _failures: Array[String] = []
const BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var payload: Dictionary = RUNNER.new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	for frame in payload.get("timeline", []):
		for row in (frame as Dictionary).get("entities", []):
			var p := row.get("position", Vector2.ZERO) as Vector2
			if not BOUNDS.has_point(p):
				_failures.append("out-of-bounds entity %s at %s" % [str(row.get("entity_id", "")), p])
				break
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 3: Run both tests to verify failures**

Run:
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_no_teleport_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_boundary_clamp_test.gd`
Expected: FAIL on old behavior.

- [ ] **Step 4: Implement blended steering with hysteresis and bounded integration**

```gdscript
func _select_blended_direction(entity: Dictionary, target: Dictionary, context: Dictionary, scores: Dictionary) -> Vector2:
	var ranked := _rank_actions(scores)
	var main_action := String(ranked[0])
	var alt_action := String(ranked[1])
	main_action = _apply_action_hysteresis(entity, main_action, scores)
	var main_dir := _direction_for_action(main_action, entity, target)
	var alt_dir := _direction_for_action(alt_action, entity, target)
	return (main_dir * 0.75 + alt_dir * 0.25).normalized()

func _integrate_motion(entity: Dictionary, desired_direction: Vector2, max_speed: float, dt: float) -> Vector2:
	var velocity := entity.get("velocity", Vector2.ZERO) as Vector2
	var desired_velocity := desired_direction * max_speed
	var accel_limit := 220.0
	var dv := desired_velocity - velocity
	if dv.length() > accel_limit * dt:
		dv = dv.normalized() * accel_limit * dt
	velocity += dv
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	entity["velocity"] = velocity
	return velocity
```

- [ ] **Step 5: Clamp final position to arena and update boundary risk helper**

```gdscript
const ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)

func _clamp_to_arena(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, ARENA_BOUNDS.position.x, ARENA_BOUNDS.end.x),
		clampf(position.y, ARENA_BOUNDS.position.y, ARENA_BOUNDS.end.y)
	)
```

- [ ] **Step 6: Run both tests to verify pass**

Run:
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_no_teleport_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_boundary_clamp_test.gd`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add scripts/battle_runtime/battle_ai_system.gd tests/runtime_ai_no_teleport_test.gd tests/runtime_ai_boundary_clamp_test.gd
git commit -m "feat: enforce bounded adaptive steering with no-teleport guarantees"
```

---

### Task 3: Implement Breakout Response and Anti-Stall Guarantees

**Files:**
- Modify: `scripts/battle_runtime/battle_ai_system.gd`
- Create: `tests/runtime_ai_breakout_response_test.gd`

- [ ] **Step 1: Write failing breakout response test**

```gdscript
extends SceneTree
const AI := preload("res://scripts/battle_runtime/battle_ai_system.gd")
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ai := AI.new()
	var state := {
		"tick_rate": 10,
		"entities": [
			{"entity_id":"ally_0","side":"ally","alive":true,"hp":20.0,"max_hp":100.0,"attack_range":70.0,"base_move_speed":120.0,"position":Vector2(300,300),"recent_damage_pressure":1.0},
			{"entity_id":"enemy_0","side":"enemy","alive":true,"hp":100.0,"max_hp":100.0,"attack_range":100.0,"base_move_speed":100.0,"position":Vector2(340,300)},
			{"entity_id":"enemy_1","side":"enemy","alive":true,"hp":100.0,"max_hp":100.0,"attack_range":100.0,"base_move_speed":100.0,"position":Vector2(340,340)}
		]
	}
	var start := ((state["entities"] as Array)[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	for _i in range(8):
		ai.tick(state)
	var end := (((state["entities"] as Array)[0] as Dictionary).get("position", Vector2.ZERO) as Vector2)
	if end.distance_to(start) < 20.0:
		_failures.append("expected breakout displacement under pressure")
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_breakout_response_test.gd`
Expected: FAIL when breakout signal is not strong enough.

- [ ] **Step 3: Implement pressure memory + breakout boost + decay**

```gdscript
func _update_pressure_memory(entity: Dictionary) -> void:
	var pressure := float(entity.get("recent_damage_pressure", 0.0))
	pressure = pressure * 0.85
	entity["recent_damage_pressure"] = clampf(pressure, 0.0, 2.0)

func _boost_breakout_for_trap(context: Dictionary, scores: Dictionary) -> Dictionary:
	var trapped := float(context.get("local_outnumbered", 0.0)) > 0.5 and float(context.get("hp_ratio", 1.0)) < 0.55
	if trapped:
		scores["breakout"] = float(scores.get("breakout", 0.0)) + 0.9
	return scores
```

- [ ] **Step 4: Run breakout test and reachability test**

Run:
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_breakout_response_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_engage_reachability_test.gd`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/battle_runtime/battle_ai_system.gd tests/runtime_ai_breakout_response_test.gd
git commit -m "feat: add breakout response under pressure and trap conditions"
```

---

### Task 4: Add Observe-Side Motion Interpolation (Visual Only)

**Files:**
- Modify: `scripts/observe/token_view.gd`
- Create: `tests/observe_motion_smoothing_visual_test.gd`

- [ ] **Step 1: Write failing observe smoothing test**

```gdscript
extends SceneTree
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	token.apply_snapshot({"entity_id":"u1","display_name":"单位","side":"ally","hp_ratio":1.0,"position":Vector2(100,100)})
	token.apply_snapshot({"entity_id":"u1","display_name":"单位","side":"ally","hp_ratio":1.0,"position":Vector2(150,100)})
	var p0 := token.position
	await process_frame
	var p1 := token.position
	if p1 == p0:
		_failures.append("expected interpolated movement between snapshots")
	token.free()
	_finish()

func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
```

- [ ] **Step 2: Run test to verify it fails**

Run: ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_motion_smoothing_visual_test.gd`
Expected: FAIL if token snaps directly and does not animate.

- [ ] **Step 3: Implement interpolation with snap guard**

```gdscript
const POSITION_SMOOTH_SPEED := 14.0
const POSITION_SNAP_DISTANCE := 120.0

var _target_position := Vector2.ZERO
var _has_target_position := false

func apply_snapshot(snapshot: Dictionary) -> void:
	var next_position := Vector2(round(world_position.x), round(world_position.y))
	if not _has_target_position:
		position = next_position
		_target_position = next_position
		_has_target_position = true
	else:
		if position.distance_to(next_position) > POSITION_SNAP_DISTANCE:
			position = next_position
		_target_position = next_position
		set_process(true)

func _process(delta: float) -> void:
	var next := position.lerp(_target_position, clampf(delta * POSITION_SMOOTH_SPEED, 0.0, 1.0))
	position = Vector2(round(next.x), round(next.y))
	if position == _target_position:
		set_process(false)
```

- [ ] **Step 4: Run test to verify pass**

Run: ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_motion_smoothing_visual_test.gd`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/observe/token_view.gd tests/observe_motion_smoothing_visual_test.gd
git commit -m "feat: add observe-side token interpolation smoothing"
```

---

### Task 5: Regression Gate + Documentation Sync

**Files:**
- Modify: `docs/HANDOFF.md`

- [ ] **Step 1: Run full targeted regression set**

Run:
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_no_teleport_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_boundary_clamp_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_engage_reachability_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_ai_breakout_response_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_determinism_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_engagement_pacing_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/runtime_parallel_attack_same_tick_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_motion_smoothing_visual_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_token_render_test.gd`
- ` /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/observe_battlefield_playable_area_test.gd`

Expected: all PASS.

- [ ] **Step 2: Update handoff with concrete outcomes**

```markdown
## 本次改动（2026-03-31，Adaptive AI Movement）
- 新增评分驱动自适应行动：接敌/避敌/突围/侧移
- 增加 runtime 无瞬移与边界硬约束
- 增加 observe 显示层位置插值平滑
- 新增测试：runtime_ai_no_teleport / boundary_clamp / engage_reachability / breakout_response / observe_motion_smoothing_visual
- 关键回归通过：runtime_determinism / engagement_pacing / parallel_attack_same_tick / observe_token_render
```

- [ ] **Step 3: Commit final integration**

```bash
git add docs/HANDOFF.md
git commit -m "docs: record adaptive ai movement rollout and regression status"
```

---

## Self-Review

### Spec coverage check
- 自适应决策（寻敌/避敌/突围/侧移）：Task 1 + Task 3
- 平滑与无瞬移：Task 2 + Task 4
- 边界约束：Task 2
- 可进入交战距离，避免停滞：Task 1 + Task 3
- 回归与验收指标：Task 5

### Placeholder scan
- 无 `TBD`、`TODO`、`implement later`。
- 每个代码步骤都给出实际代码片段和命令。

### Type/interface consistency
- Runtime AI 改动集中于 `battle_ai_system.gd`。
- 观察层平滑集中于 `token_view.gd`。
- 测试命名与 spec 一致：`runtime_ai_*`、`observe_motion_smoothing_visual_test.gd`。
