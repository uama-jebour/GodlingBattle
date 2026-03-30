extends RefCounted


func tick(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	if entities.is_empty():
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
		return

	if int(state.get("elapsed_ticks", 0)) == 10:
		for entity in entities:
			if str(entity.get("side", "")) != "enemy" or not bool(entity.get("alive", false)):
				continue
			entity["alive"] = false
			state["casualties"].append(str(entity.get("entity_id", "")))
			state["log_entries"].append({
				"tick": 10,
				"type": "enemy_down",
				"entity_id": str(entity.get("entity_id", ""))
			})
		state["completed"] = true
