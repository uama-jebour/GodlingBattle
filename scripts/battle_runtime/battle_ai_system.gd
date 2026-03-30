extends RefCounted


func tick(state: Dictionary) -> void:
	_update_entity_positions(state)
	if int(state.get("elapsed_ticks", 0)) == 0 and not state.get("strategies", []).is_empty():
		var first_strategy: Dictionary = state.get("strategies", [])[0]
		state["triggered_strategies"].append({
			"strategy_id": str(first_strategy.get("strategy_id", "")),
			"tick": 0
		})


func _update_entity_positions(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	var step_seconds := 1.0 / float(max(int(state.get("tick_rate", 10)), 1))
	for entity in entities:
		if not bool(entity.get("alive", false)):
			continue
		var position = entity.get("position", Vector2.ZERO)
		if not (position is Vector2):
			position = Vector2.ZERO
		var move_speed := float(entity.get("move_speed", 0.0))
		var side := str(entity.get("side", ""))
		var direction := 1.0
		if side == "enemy":
			direction = -1.0
		position.x += move_speed * step_seconds * direction
		entity["position"] = position
