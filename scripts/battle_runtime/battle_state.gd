extends RefCounted

const MAX_SECONDS := 600
const TICK_RATE := 10
const CONTENT := preload("res://autoload/battle_content.gd")


func initialize(setup: Dictionary) -> Dictionary:
	var content: Node = CONTENT.new()
	var battle_id := str(setup.get("battle_id", ""))
	var battle_def: Dictionary = content.get_battle(battle_id)
	var seed := int(setup.get("seed", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var entities := _spawn_entities_from_setup(setup, battle_def, content)
	var strategies := _resolve_strategies(setup, content)
	var events := _resolve_events(battle_def, content)
	content.free()
	return {
		"setup": setup.duplicate(true),
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


func _spawn_entities_from_setup(setup: Dictionary, battle_def: Dictionary, content: Node) -> Array:
	var entities: Array = []
	var hero_id := str(setup.get("hero_id", ""))
	if not hero_id.is_empty():
		entities.append(_create_entity(hero_id, "hero", content.get_unit(hero_id), entities.size()))
	for ally_id in setup.get("ally_ids", []):
		var ally_id_text := str(ally_id)
		entities.append(_create_entity(ally_id_text, "ally", content.get_unit(ally_id_text), entities.size()))
	for enemy_id in battle_def.get("enemy_units", []):
		var enemy_id_text := str(enemy_id)
		var unit_def: Dictionary = content.get_unit(enemy_id_text)
		if unit_def.is_empty():
			unit_def = _fallback_enemy_def(enemy_id_text)
		entities.append(_create_entity(enemy_id_text, "enemy", unit_def, entities.size()))
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


func _create_entity(unit_id: String, side: String, unit_def: Dictionary, index: int) -> Dictionary:
	var hp := float(unit_def.get("max_hp", 30.0))
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
		"attack_range": float(unit_def.get("attack_range", 1.0)),
		"base_move_speed": move_speed,
		"move_speed": move_speed,
		"tags": unit_def.get("tags", []).duplicate(),
		"attack_cooldown_ticks": 0,
		"slow_ratio": 0.0,
		"slow_ticks_remaining": 0,
		"position": _initial_position(side, index)
	}


func _fallback_enemy_def(enemy_id: String) -> Dictionary:
	return {
		"unit_id": enemy_id,
		"display_name": "敌方单位",
		"max_hp": 30.0,
		"attack_power": 3.0,
		"attack_speed": 1.0,
		"attack_range": 1.0,
		"move_speed": 8.0
	}


func _initial_position(side: String, index: int) -> Vector2:
	if side == "enemy":
		return Vector2(500.0, 260.0 + float(index) * 90.0)
	if side == "hero":
		return Vector2(320.0, 280.0)
	return Vector2(260.0, 380.0 + float(index) * 90.0)
