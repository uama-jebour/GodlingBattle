extends RefCounted


func tick(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	if entities.is_empty():
		state["completed"] = true
		return

	var tick_now := int(state.get("elapsed_ticks", 0))
	_apply_ally_attrition(state, entities, tick_now)

	if tick_now == 80:
		_defeat_all_enemies(state, entities, tick_now)
		state["completed"] = true
		return

	var has_hero_alive := false
	var has_enemy_alive := false
	for entity in entities:
		if not bool(entity.get("alive", false)):
			continue
		var side := str(entity.get("side", ""))
		if side == "hero":
			has_hero_alive = true
		elif side == "enemy":
			has_enemy_alive = true
	if not has_hero_alive or not has_enemy_alive:
		state["completed"] = true


func _apply_ally_attrition(state: Dictionary, entities: Array, tick_now: int) -> void:
	if tick_now <= 0:
		return
	for entity in entities:
		if str(entity.get("side", "")) != "ally" or not bool(entity.get("alive", false)):
			continue
		var next_hp := maxf(0.0, float(entity.get("hp", 0.0)) - 1.0)
		entity["hp"] = next_hp
		if next_hp <= 0.0:
			entity["alive"] = false
			_record_casualty(state, entity)
			state["log_entries"].append({
				"tick": tick_now,
				"type": "ally_down",
				"entity_id": str(entity.get("entity_id", ""))
			})
		break


func _defeat_all_enemies(state: Dictionary, entities: Array, tick_now: int) -> void:
	for entity in entities:
		if str(entity.get("side", "")) != "enemy" or not bool(entity.get("alive", false)):
			continue
		entity["alive"] = false
		_record_casualty(state, entity)
		state["log_entries"].append({
			"tick": tick_now,
			"type": "enemy_down",
			"entity_id": str(entity.get("entity_id", ""))
		})


func _record_casualty(state: Dictionary, entity: Dictionary) -> void:
	var entity_id := str(entity.get("entity_id", ""))
	var casualties: Array = state.get("casualties", [])
	if entity_id in casualties:
		return
	casualties.append(entity_id)
	state["casualties"] = casualties
