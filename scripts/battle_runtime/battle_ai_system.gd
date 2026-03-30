extends RefCounted


func tick(state: Dictionary) -> void:
	if int(state.get("elapsed_ticks", 0)) == 0:
		state["entities"] = [
			{"entity_id": "hero_1", "side": "hero", "alive": true, "hp": 100.0},
			{"entity_id": "enemy_1", "side": "enemy", "alive": true, "hp": 30.0}
		]
