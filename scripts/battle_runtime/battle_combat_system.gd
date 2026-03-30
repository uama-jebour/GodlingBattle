extends RefCounted


func tick(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	if entities.size() < 2:
		state["completed"] = true
		return
	if int(state.get("elapsed_ticks", 0)) == 10:
		entities[1]["alive"] = false
		state["log_entries"].append({"tick": 10, "type": "enemy_down", "entity_id": "enemy_1"})
		state["completed"] = true
