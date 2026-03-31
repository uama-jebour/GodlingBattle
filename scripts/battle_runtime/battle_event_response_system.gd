extends RefCounted

const CONTENT := preload("res://autoload/battle_content.gd")
const DISTANCE_SCALE := 20.0
const ENEMY_HP_MULTIPLIER := 1.85
const ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)


func tick(state: Dictionary) -> void:
	var events: Array = state.get("events", [])
	if events.is_empty():
		return
	var tick_now := int(state.get("elapsed_ticks", 0))
	if not state.has("event_runtime"):
		var runtime_state := {}
		for event_def in events:
			runtime_state[str(event_def.get("event_id", ""))] = {"stage": "idle", "warning_tick": -1}
		state["event_runtime"] = runtime_state
	var event_runtime: Dictionary = state.get("event_runtime", {})

	for event_def in events:
		var event_id := str(event_def.get("event_id", ""))
		if event_id.is_empty():
			continue
		var runtime: Dictionary = event_runtime.get(event_id, {"stage": "idle", "warning_tick": -1})
		var stage := str(runtime.get("stage", "idle"))
		if stage == "done":
			continue
		if stage == "idle" and _should_warn(event_def, state, tick_now):
			var response_preview := _preview_response(event_def, state)
			runtime["stage"] = "warning"
			runtime["warning_tick"] = tick_now
			var warning_row := {
				"tick": tick_now,
				"type": "event_warning",
				"event_id": event_id
			}
			warning_row["response_ready"] = bool(response_preview.get("ready", false))
			warning_row["response_strategy_id"] = str(response_preview.get("strategy_id", ""))
			warning_row["response_missing_reason"] = str(response_preview.get("missing_reason", ""))
			state["log_entries"].append(warning_row)
		elif stage == "warning":
			var warning_tick := int(runtime.get("warning_tick", tick_now))
			var warning_duration_ticks := _warning_duration_ticks(event_def, state)
			if tick_now >= warning_tick + warning_duration_ticks:
				var responded := _check_response(event_def, state, tick_now)
				state["log_entries"].append({
					"tick": tick_now,
					"type": "event_resolve",
					"event_id": event_id,
					"responded": responded
				})
				state["triggered_events"].append({
					"event_id": event_id,
					"tick": tick_now,
					"responded": responded
				})
				if not responded:
					state["log_entries"].append({
						"tick": tick_now,
						"type": "event_unresolved_effect",
						"event_id": event_id
					})
					_apply_unresolved_effect(event_def, state, tick_now, event_id)
				runtime["stage"] = "done"
		event_runtime[event_id] = runtime
	state["event_runtime"] = event_runtime


func _should_warn(event_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var trigger_def: Dictionary = event_def.get("trigger_def", {})
	return _trigger_matches(trigger_def, state, tick_now)


func _warning_duration_ticks(event_def: Dictionary, state: Dictionary) -> int:
	var warning_seconds := float(event_def.get("warning_seconds", 0.0))
	var tick_rate := int(state.get("tick_rate", 10))
	return max(1, int(round(warning_seconds * float(tick_rate))))


func _check_response(event_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var preview := _preview_response(event_def, state)
	var strategy_id := str(preview.get("strategy_id", ""))
	if strategy_id.is_empty():
		return false
	state["triggered_strategies"].append({
		"strategy_id": strategy_id,
		"tick": tick_now
	})
	return true


func _preview_response(event_def: Dictionary, state: Dictionary) -> Dictionary:
	var response_tag := str(event_def.get("response_tag", ""))
	var response_level := int(event_def.get("response_level", -1))
	for strategy_def in state.get("strategies", []):
		var trigger_def: Dictionary = strategy_def.get("trigger_def", {})
		if str(trigger_def.get("type", "")) != "event_response":
			continue
		if str(trigger_def.get("response_tag", "")) != response_tag:
			continue
		if int(trigger_def.get("response_level", -1)) != response_level:
			continue
		return {
			"ready": true,
			"strategy_id": str(strategy_def.get("strategy_id", "")),
			"missing_reason": ""
		}
	return {
		"ready": false,
		"strategy_id": "",
		"missing_reason": "未携带对应对策"
	}


func _trigger_matches(trigger_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var trigger_type := str(trigger_def.get("type", ""))
	if trigger_type == "any":
		for rule in trigger_def.get("rules", []):
			if _rule_matches(rule, state, tick_now):
				return true
		return false
	return _rule_matches(trigger_def, state, tick_now)


func _rule_matches(rule: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var rule_type := str(rule.get("type", ""))
	if rule_type == "elapsed_gte":
		var threshold_seconds := float(rule.get("value", 0.0))
		var tick_rate := int(state.get("tick_rate", 10))
		var elapsed_seconds := float(tick_now) / float(tick_rate)
		return elapsed_seconds >= threshold_seconds
	if rule_type == "ally_hp_ratio_lte":
		var threshold := float(rule.get("value", 0.0))
		for entity in state.get("entities", []):
			if str(entity.get("side", "")) != "ally":
				continue
			var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
			var hp_ratio := float(entity.get("hp", 0.0)) / max_hp
			if hp_ratio <= threshold:
				return true
		return false
	return false


func _apply_unresolved_effect(event_def: Dictionary, state: Dictionary, tick_now: int, event_id: String) -> void:
	var unresolved_effect_def: Dictionary = event_def.get("unresolved_effect_def", {})
	var effect_type := str(unresolved_effect_def.get("type", ""))
	if effect_type == "summon":
		_apply_unresolved_summon(unresolved_effect_def, state, tick_now, event_id)


func _apply_unresolved_summon(effect_def: Dictionary, state: Dictionary, tick_now: int, event_id: String) -> void:
	var unit_id := str(effect_def.get("unit_id", ""))
	if unit_id.is_empty():
		return
	var count := maxi(1, int(effect_def.get("count", 1)))
	var content: Node = CONTENT.new()
	var unit_def: Dictionary = content.get_unit(unit_id)
	content.free()
	if unit_def.is_empty():
		return

	var entities: Array = state.get("entities", [])
	for _i in range(count):
		var entity := _build_summoned_enemy_entity(unit_id, unit_def, state, entities)
		entities.append(entity)
		state["log_entries"].append({
			"tick": tick_now,
			"type": "enemy_spawn",
			"event_id": event_id,
			"entity_id": str(entity.get("entity_id", "")),
			"unit_id": unit_id
		})
	state["entities"] = entities


func _build_summoned_enemy_entity(unit_id: String, unit_def: Dictionary, state: Dictionary, entities: Array) -> Dictionary:
	var spawn_serial := _next_spawn_serial(state, unit_id)
	var entity_id := _unique_summoned_entity_id(unit_id, spawn_serial, entities)
	var hp := float(unit_def.get("max_hp", 30.0)) * ENEMY_HP_MULTIPLIER
	var move_speed := float(unit_def.get("move_speed", 6.0))
	return {
		"entity_id": entity_id,
		"unit_id": unit_id,
		"display_name": str(unit_def.get("display_name", unit_id)),
		"side": "enemy",
		"alive": true,
		"hp": hp,
		"max_hp": hp,
		"attack_power": float(unit_def.get("attack_power", 3.0)),
		"attack_speed": float(unit_def.get("attack_speed", 1.0)),
		"attack_range": float(unit_def.get("attack_range", 1.0)) * DISTANCE_SCALE,
		"base_move_speed": move_speed * DISTANCE_SCALE,
		"move_speed": move_speed * DISTANCE_SCALE,
		"tags": (unit_def.get("tags", []) as Array).duplicate(),
		"attack_cooldown_ticks": 0,
		"slow_ratio": 0.0,
		"slow_ticks_remaining": 0,
		"position": _summoned_enemy_position(state, entities)
	}


func _next_spawn_serial(state: Dictionary, unit_id: String) -> int:
	var spawn_serial_by_unit: Dictionary = state.get("spawn_serial_by_unit", {})
	var serial := int(spawn_serial_by_unit.get(unit_id, 0))
	spawn_serial_by_unit[unit_id] = serial + 1
	state["spawn_serial_by_unit"] = spawn_serial_by_unit
	return serial


func _unique_summoned_entity_id(unit_id: String, serial: int, entities: Array) -> String:
	var candidate := "%s_spawn_%d" % [unit_id, serial]
	if not _entity_id_exists(candidate, entities):
		return candidate
	var next_serial := serial + 1
	while true:
		candidate = "%s_spawn_%d" % [unit_id, next_serial]
		if not _entity_id_exists(candidate, entities):
			return candidate
		next_serial += 1
	return candidate


func _entity_id_exists(entity_id: String, entities: Array) -> bool:
	for row in entities:
		if str((row as Dictionary).get("entity_id", "")) == entity_id:
			return true
	return false


func _summoned_enemy_position(state: Dictionary, entities: Array) -> Vector2:
	var anchor := Vector2(700.0, 360.0)
	var enemy_rows: Array[Dictionary] = []
	for row in entities:
		var entity := row as Dictionary
		if not bool(entity.get("alive", false)):
			continue
		if str(entity.get("side", "")) != "enemy":
			continue
		enemy_rows.append(entity)
	if not enemy_rows.is_empty():
		var sum := Vector2.ZERO
		for entity in enemy_rows:
			sum += _position_of(entity)
		anchor = sum / float(enemy_rows.size())
		anchor.x = maxf(anchor.x + 56.0, 620.0)
	var rng := state.get("rng", null) as RandomNumberGenerator
	var jitter := Vector2.ZERO
	if rng != null:
		jitter = Vector2(
			rng.randf_range(-22.0, 22.0),
			rng.randf_range(-68.0, 68.0)
		)
	return _clamp_to_arena(anchor + jitter)


func _position_of(entity: Dictionary) -> Vector2:
	var raw = entity.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _clamp_to_arena(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, ARENA_BOUNDS.position.x, ARENA_BOUNDS.end.x),
		clampf(position.y, ARENA_BOUNDS.position.y, ARENA_BOUNDS.end.y)
	)
