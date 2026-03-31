extends RefCounted

const MAX_SECONDS := 600
const TICK_RATE := 10
const DISTANCE_SCALE := 20.0
const ENEMY_HP_MULTIPLIER := 1.85
const ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)
const SPAWN_JITTER_X := 28.0
const SPAWN_JITTER_Y := 0.0
const CONTENT := preload("res://autoload/battle_content.gd")


func initialize(setup: Dictionary) -> Dictionary:
	var content: Node = CONTENT.new()
	var battle_id := str(setup.get("battle_id", ""))
	var battle_def: Dictionary = content.get_battle(battle_id)
	var seed := int(setup.get("seed", 0))
	if seed == 0:
		seed = _fallback_seed()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var normalized_setup := setup.duplicate(true)
	normalized_setup["seed"] = seed
	var entities := _spawn_entities_from_setup(normalized_setup, battle_def, content, rng)
	var strategies := _resolve_strategies(setup, content)
	var events := _resolve_events(battle_def, content)
	content.free()
	return {
		"setup": normalized_setup,
		"seed": seed,
		"rng": rng,
		"tick_rate": TICK_RATE,
		"elapsed_ticks": 0,
		"max_ticks": MAX_SECONDS * TICK_RATE,
		"entities": entities,
		"events": events,
		"strategies": strategies,
		"log_entries": [],
		"triggered_events": [],
		"triggered_strategies": [],
		"casualties": [],
		"completed": false
	}


func _spawn_entities_from_setup(setup: Dictionary, battle_def: Dictionary, content: Node, rng: RandomNumberGenerator) -> Array:
	var entities: Array = []
	var randomized_spawn := bool(setup.get("randomized_spawn", false))
	var hero_id := str(setup.get("hero_id", ""))
	if not hero_id.is_empty():
		entities.append(_create_entity(hero_id, "hero", content.get_unit(hero_id), entities.size(), rng, randomized_spawn))
	for ally_id in setup.get("ally_ids", []):
		var ally_id_text := str(ally_id)
		entities.append(_create_entity(ally_id_text, "ally", content.get_unit(ally_id_text), entities.size(), rng, randomized_spawn))
	for enemy_id in battle_def.get("enemy_units", []):
		var enemy_id_text := str(enemy_id)
		var unit_def: Dictionary = content.get_unit(enemy_id_text)
		if unit_def.is_empty():
			unit_def = _fallback_enemy_def(enemy_id_text)
		entities.append(_create_entity(enemy_id_text, "enemy", unit_def, entities.size(), rng, randomized_spawn))
	return entities


func _resolve_strategies(setup: Dictionary, content: Node) -> Array:
	var rows: Array = []
	for strategy_id in setup.get("strategy_ids", []):
		var strategy_id_text := str(strategy_id)
		var strategy_def: Dictionary = content.get_strategy(strategy_id_text)
		if strategy_def.is_empty():
			continue
		rows.append(strategy_def)
	return rows


func _resolve_events(battle_def: Dictionary, content: Node) -> Array:
	var rows: Array = []
	for event_id in battle_def.get("event_ids", []):
		var event_id_text := str(event_id)
		var event_def: Dictionary = content.get_event(event_id_text)
		if event_def.is_empty():
			continue
		rows.append(event_def)
	return rows


func _create_entity(unit_id: String, side: String, unit_def: Dictionary, index: int, rng: RandomNumberGenerator, randomized_spawn: bool) -> Dictionary:
	var hp := float(unit_def.get("max_hp", 30.0))
	if side == "enemy":
		hp *= ENEMY_HP_MULTIPLIER
	var move_speed := float(unit_def.get("move_speed", 6.0))
	return {
		"entity_id": "%s_%d" % [unit_id, index],
		"unit_id": unit_id,
		"display_name": str(unit_def.get("display_name", unit_id)),
		"side": side,
		"alive": true,
		"hp": hp,
		"max_hp": hp,
		"attack_power": float(unit_def.get("attack_power", 3.0)),
		"attack_speed": float(unit_def.get("attack_speed", 1.0)),
		"attack_range": float(unit_def.get("attack_range", 1.0)) * DISTANCE_SCALE,
		"base_move_speed": move_speed * DISTANCE_SCALE,
		"move_speed": move_speed * DISTANCE_SCALE,
		"tags": unit_def.get("tags", []).duplicate(),
		"attack_cooldown_ticks": 0,
		"slow_ratio": 0.0,
		"slow_ticks_remaining": 0,
		"position": _initial_position(side, index, rng, randomized_spawn)
	}


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


func _initial_position(side: String, index: int, rng: RandomNumberGenerator, randomized_spawn: bool) -> Vector2:
	var base_position := Vector2.ZERO
	if side == "enemy":
		base_position = Vector2(500.0, 260.0 + float(index) * 90.0)
	elif side == "hero":
		base_position = Vector2(320.0, 280.0)
	else:
		base_position = Vector2(260.0, 380.0 + float(index) * 90.0)
	var jitter := Vector2.ZERO
	if randomized_spawn:
		jitter = Vector2(
			rng.randf_range(-SPAWN_JITTER_X, SPAWN_JITTER_X),
			rng.randf_range(-SPAWN_JITTER_Y, SPAWN_JITTER_Y)
		)
	return _clamp_to_arena(base_position + jitter)


func _clamp_to_arena(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, ARENA_BOUNDS.position.x, ARENA_BOUNDS.end.x),
		clampf(position.y, ARENA_BOUNDS.position.y, ARENA_BOUNDS.end.y)
	)


func _fallback_seed() -> int:
	var unix_seconds := int(Time.get_unix_time_from_system())
	var ticks_usec := int(Time.get_ticks_usec() & 0x7fffffff)
	return max(1, unix_seconds ^ ticks_usec)
