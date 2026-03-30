extends RefCounted


func tick(state: Dictionary) -> void:
	_update_entity_positions(state)


func _update_entity_positions(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	var step_seconds: float = 1.0 / float(maxi(int(state.get("tick_rate", 10)), 1))
	for index in range(entities.size()):
		var entity: Dictionary = entities[index]
		if not bool(entity.get("alive", false)):
			continue
		var target_index: int = _find_nearest_opponent_index(entity, entities)
		if target_index < 0:
			continue
		var target: Dictionary = entities[target_index]
		var position: Vector2 = _position_of(entity)
		var target_position: Vector2 = _position_of(target)
		var offset: Vector2 = target_position - position
		var distance: float = offset.length()
		var attack_range: float = maxf(float(entity.get("attack_range", 0.0)), 0.0)
		if distance <= attack_range or distance <= 0.001:
			continue
		var move_speed: float = _effective_move_speed(entity)
		var max_step: float = move_speed * step_seconds
		var desired_step: float = minf(max_step, maxf(distance - attack_range, 0.0))
		position += offset.normalized() * desired_step
		entity["position"] = position
		entities[index] = entity
	state["entities"] = entities


func _find_nearest_opponent_index(attacker: Dictionary, entities: Array) -> int:
	var attacker_side: String = str(attacker.get("side", ""))
	var attacker_pos: Vector2 = _position_of(attacker)
	var best_index: int = -1
	var best_distance: float = INF
	for index in range(entities.size()):
		var target: Dictionary = entities[index]
		if not bool(target.get("alive", false)):
			continue
		if _is_same_team(attacker_side, str(target.get("side", ""))):
			continue
		var distance: float = attacker_pos.distance_to(_position_of(target))
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _is_same_team(side_a: String, side_b: String) -> bool:
	if side_a == "enemy":
		return side_b == "enemy"
	if side_b == "enemy":
		return false
	return true


func _position_of(entity: Dictionary) -> Vector2:
	var position = entity.get("position", Vector2.ZERO)
	if position is Vector2:
		return position
	return Vector2.ZERO


func _effective_move_speed(entity: Dictionary) -> float:
	var speed: float = maxf(float(entity.get("base_move_speed", entity.get("move_speed", 0.0))), 0.0)
	var slow_ticks: int = int(entity.get("slow_ticks_remaining", 0))
	if slow_ticks <= 0:
		return speed
	var slow_ratio: float = clampf(float(entity.get("slow_ratio", 0.0)), 0.0, 0.95)
	return speed * (1.0 - slow_ratio)
