extends RefCounted

const ACTION_APPROACH := "approach"
const ACTION_KITE := "kite"
const ACTION_BREAKOUT := "breakout"
const ACTION_FLANK := "flank"
const ACTION_SWITCH_THRESHOLD := 0.12
const SCORE_BLEND_PRIMARY := 0.75
const SCORE_BLEND_SECONDARY := 0.25
const MAX_STEP_PER_TICK := 18.0
const ACCEL_PER_SECOND := 220.0
const MAX_PRESSURE := 2.0
const PRESSURE_DECAY := 0.84
const PRESSURE_GAIN_SCALE := 0.06
const LOCAL_EVAL_RADIUS := 180.0
const ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)
const ARENA_EPSILON := 0.001


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
		_update_pressure_memory(entity)
		var context := _build_context(entity, target, entities)
		var distance := float(context.get("distance", 0.0))
		if distance <= 0.001:
			entity["velocity"] = Vector2.ZERO
			entities[index] = entity
			continue
		var move_speed: float = _effective_move_speed(entity)
		var scores := _score_actions(context)
		var direction := _select_blended_direction(entity, target, scores)
		if direction == Vector2.ZERO:
			entity["velocity"] = Vector2.ZERO
			entities[index] = entity
			continue
		var velocity := _integrate_velocity(entity, direction, move_speed, step_seconds)
		var step := velocity * step_seconds
		if step.length() > MAX_STEP_PER_TICK:
			step = step.normalized() * MAX_STEP_PER_TICK
			velocity = step / maxf(step_seconds, 0.001)
		var next_position := _position_of(entity) + step
		entity["velocity"] = velocity
		entity["position"] = _clamp_to_arena(next_position)
		entities[index] = entity
	state["entities"] = entities


func _build_context(entity: Dictionary, target: Dictionary, entities: Array) -> Dictionary:
	var self_pos := _position_of(entity)
	var target_pos := _position_of(target)
	var distance := self_pos.distance_to(target_pos)
	var attack_range := maxf(float(entity.get("attack_range", 0.0)), 1.0)
	var target_range := maxf(float(target.get("attack_range", 0.0)), 1.0)
	return {
		"distance": distance,
		"attack_range": attack_range,
		"range_advantage": attack_range - target_range,
		"local_outnumbered": _local_outnumbered(entity, entities),
		"pressure": float(entity.get("recent_damage_pressure", 0.0)),
		"hp_ratio": _hp_ratio(entity),
		"boundary_risk": _boundary_risk(self_pos)
	}


func _score_actions(context: Dictionary) -> Dictionary:
	var distance := float(context.get("distance", 0.0))
	var attack_range := maxf(float(context.get("attack_range", 1.0)), 1.0)
	var range_advantage := float(context.get("range_advantage", 0.0))
	var pressure := float(context.get("pressure", 0.0))
	var outnumbered := float(context.get("local_outnumbered", 0.0))
	var hp_ratio := float(context.get("hp_ratio", 1.0))
	var boundary_risk := float(context.get("boundary_risk", 0.0))
	var distance_ratio := distance / attack_range
	return {
		ACTION_APPROACH: distance_ratio * 0.90 - pressure * 0.40 - maxf(0.0, outnumbered) * 0.30,
		ACTION_KITE: maxf(0.0, range_advantage / attack_range) * 0.70 + pressure * 0.65 - distance_ratio * 0.25,
		ACTION_BREAKOUT: pressure * 0.85 + maxf(0.0, outnumbered) * 0.70 + (1.0 - hp_ratio) * 0.70,
		ACTION_FLANK: clampf(1.2 - absf(distance - attack_range) / attack_range, 0.0, 1.2) * (1.0 - boundary_risk)
	}


func _select_blended_direction(entity: Dictionary, target: Dictionary, scores: Dictionary) -> Vector2:
	var ranked := _rank_actions(scores)
	if ranked.is_empty():
		return Vector2.ZERO
	var main_action := String(ranked[0])
	main_action = _apply_action_hysteresis(entity, main_action, scores)
	var secondary_action := main_action
	if ranked.size() > 1:
		secondary_action = String(ranked[1])
	var main_direction := _direction_for_action(main_action, entity, target)
	var secondary_direction := _direction_for_action(secondary_action, entity, target)
	var blended := main_direction * SCORE_BLEND_PRIMARY + secondary_direction * SCORE_BLEND_SECONDARY
	if blended.length_squared() <= 0.0001:
		return main_direction.normalized()
	return blended.normalized()


func _rank_actions(scores: Dictionary) -> Array:
	var keys := scores.keys()
	keys.sort_custom(func(a, b) -> bool:
		var sa := float(scores.get(a, -INF))
		var sb := float(scores.get(b, -INF))
		if is_equal_approx(sa, sb):
			return String(a) < String(b)
		return sa > sb
	)
	return keys


func _apply_action_hysteresis(entity: Dictionary, candidate: String, scores: Dictionary) -> String:
	var current := str(entity.get("ai_action", ""))
	if current.is_empty():
		entity["ai_action"] = candidate
		return candidate
	var current_score := float(scores.get(current, -INF))
	var candidate_score := float(scores.get(candidate, -INF))
	if candidate_score < current_score + ACTION_SWITCH_THRESHOLD:
		return current
	entity["ai_action"] = candidate
	return candidate


func _direction_for_action(action: String, entity: Dictionary, target: Dictionary) -> Vector2:
	var self_pos := _position_of(entity)
	var target_pos := _position_of(target)
	var radial := (target_pos - self_pos).normalized()
	if radial == Vector2.ZERO:
		return Vector2.ZERO
	var tangent := _orbit_tangent(entity, radial)
	match action:
		ACTION_KITE:
			return (tangent * 0.35 - radial * 0.65).normalized()
		ACTION_BREAKOUT:
			return _breakout_direction(entity, target)
		ACTION_FLANK:
			return (tangent * 0.80 + radial * 0.20).normalized()
		_:
			return radial


func _breakout_direction(entity: Dictionary, target: Dictionary) -> Vector2:
	var self_pos := _position_of(entity)
	var away := (self_pos - _position_of(target)).normalized()
	if away == Vector2.ZERO:
		away = Vector2.LEFT
	var to_center := (ARENA_BOUNDS.get_center() - self_pos).normalized()
	var tangent := _orbit_tangent(entity, away)
	var toward_center_weight := 0.45 + _boundary_risk(self_pos) * 0.55
	return (away * 0.55 + tangent * 0.20 + to_center * toward_center_weight).normalized()


func _integrate_velocity(entity: Dictionary, desired_direction: Vector2, max_speed: float, dt: float) -> Vector2:
	var velocity: Vector2 = _velocity_of(entity)
	var desired_velocity := desired_direction * max_speed
	var delta_v := desired_velocity - velocity
	var max_dv := ACCEL_PER_SECOND * dt
	if delta_v.length() > max_dv:
		delta_v = delta_v.normalized() * max_dv
	velocity += delta_v
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	return velocity


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


func _velocity_of(entity: Dictionary) -> Vector2:
	var value: Variant = entity.get("velocity", Vector2.ZERO)
	if value is Vector2:
		return value
	return Vector2.ZERO


func _orbit_tangent(entity: Dictionary, radial: Vector2) -> Vector2:
	var tangent := Vector2(-radial.y, radial.x)
	if _orbit_sign(entity) < 0.0:
		tangent = -tangent
	return tangent


func _orbit_sign(entity: Dictionary) -> float:
	var entity_id := str(entity.get("entity_id", ""))
	var checksum := 0
	for index in range(entity_id.length()):
		checksum += entity_id.unicode_at(index)
	var side := str(entity.get("side", ""))
	if side == "enemy":
		checksum += 1
	if checksum % 2 == 0:
		return -1.0
	return 1.0


func _hp_ratio(entity: Dictionary) -> float:
	var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
	return clampf(float(entity.get("hp", max_hp)) / max_hp, 0.0, 1.0)


func _boundary_risk(position: Vector2) -> float:
	var margin := 56.0
	var left := (position.x - ARENA_BOUNDS.position.x) / margin
	var right := (ARENA_BOUNDS.end.x - position.x) / margin
	var top := (position.y - ARENA_BOUNDS.position.y) / margin
	var bottom := (ARENA_BOUNDS.end.y - position.y) / margin
	var min_ratio := minf(minf(left, right), minf(top, bottom))
	return clampf(1.0 - min_ratio, 0.0, 1.0)


func _local_outnumbered(entity: Dictionary, entities: Array) -> float:
	var self_pos := _position_of(entity)
	var self_side := str(entity.get("side", ""))
	var nearby_allies := 0.0
	var nearby_enemies := 0.0
	for row in entities:
		if not bool(row.get("alive", false)):
			continue
		var pos := _position_of(row)
		if self_pos.distance_to(pos) > LOCAL_EVAL_RADIUS:
			continue
		if _is_same_team(self_side, str(row.get("side", ""))):
			nearby_allies += 1.0
		else:
			nearby_enemies += 1.0
	return nearby_enemies - nearby_allies


func _update_pressure_memory(entity: Dictionary) -> void:
	var hp_now := float(entity.get("hp", 0.0))
	var hp_prev := float(entity.get("_ai_prev_hp", hp_now))
	var damage_taken := maxf(0.0, hp_prev - hp_now)
	var pressure := float(entity.get("recent_damage_pressure", 0.0))
	pressure = pressure * PRESSURE_DECAY + damage_taken * PRESSURE_GAIN_SCALE
	entity["recent_damage_pressure"] = clampf(pressure, 0.0, MAX_PRESSURE)
	entity["_ai_prev_hp"] = hp_now


func _clamp_to_arena(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, ARENA_BOUNDS.position.x, ARENA_BOUNDS.end.x - ARENA_EPSILON),
		clampf(position.y, ARENA_BOUNDS.position.y, ARENA_BOUNDS.end.y - ARENA_EPSILON)
	)
