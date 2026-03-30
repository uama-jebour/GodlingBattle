extends RefCounted

const ALLY_TAG_ATTACK_SHIFT := "ally_tag_attack_shift"
const ENEMY_GROUP_SLOW := "enemy_group_slow"
const ENEMY_FRONT_NUKE := "enemy_front_nuke"

func tick(state: Dictionary) -> void:
	var entities: Array = state.get("entities", [])
	if entities.is_empty():
		state["completed"] = true
		return

	var tick_now := int(state.get("elapsed_ticks", 0))
	_apply_ally_attrition(state, entities, tick_now)
	_tick_status_effects(entities)
	_process_active_strategies(state, entities, tick_now)
	_process_attacks(state, entities, tick_now)

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


func _process_active_strategies(state: Dictionary, entities: Array, tick_now: int) -> void:
	var strategies: Array = state.get("strategies", [])
	if strategies.is_empty():
		return
	var tick_rate: int = maxi(int(state.get("tick_rate", 10)), 1)
	var runtime: Dictionary = _ensure_strategy_runtime(state, strategies)
	for strategy_def in strategies:
		var strategy_id: String = str(strategy_def.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		var trigger_def: Dictionary = strategy_def.get("trigger_def", {})
		if str(trigger_def.get("type", "")) != "cooldown":
			continue
		var row: Dictionary = runtime.get(strategy_id, {"cooldown_ticks_remaining": 0})
		var cooldown_ticks_remaining: int = int(row.get("cooldown_ticks_remaining", 0))
		if cooldown_ticks_remaining > 0:
			row["cooldown_ticks_remaining"] = cooldown_ticks_remaining - 1
			runtime[strategy_id] = row
			continue
		_apply_strategy_effect(strategy_def, state, entities, tick_now)
		state["triggered_strategies"].append({
			"strategy_id": strategy_id,
			"tick": tick_now
		})
		state["log_entries"].append({
			"tick": tick_now,
			"type": "strategy_cast",
			"strategy_id": strategy_id
		})
		row["cooldown_ticks_remaining"] = _strategy_cooldown_ticks(strategy_def, tick_rate)
		runtime[strategy_id] = row
	state["strategy_runtime"] = runtime


func _ensure_strategy_runtime(state: Dictionary, strategies: Array) -> Dictionary:
	var runtime: Dictionary = state.get("strategy_runtime", {})
	for strategy_def in strategies:
		var strategy_id: String = str(strategy_def.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		if runtime.has(strategy_id):
			continue
		runtime[strategy_id] = {"cooldown_ticks_remaining": 0}
	state["strategy_runtime"] = runtime
	return runtime


func _strategy_cooldown_ticks(strategy_def: Dictionary, tick_rate: int) -> int:
	var cooldown_seconds: float = maxf(float(strategy_def.get("cooldown", 0.0)), 0.0)
	return max(1, int(round(cooldown_seconds * float(tick_rate))))


func _apply_strategy_effect(strategy_def: Dictionary, state: Dictionary, entities: Array, tick_now: int) -> void:
	var effect_def: Dictionary = strategy_def.get("effect_def", {})
	var effect_type: String = str(effect_def.get("type", ""))
	var tick_rate: int = maxi(int(state.get("tick_rate", 10)), 1)
	if effect_type == ENEMY_GROUP_SLOW:
		_apply_enemy_group_slow(effect_def, entities, tick_rate)
		return
	if effect_type == ENEMY_FRONT_NUKE:
		_apply_enemy_front_nuke(effect_def, state, entities, tick_now)


func _apply_enemy_group_slow(effect_def: Dictionary, entities: Array, tick_rate: int) -> void:
	var ratio: float = clampf(float(effect_def.get("ratio", 0.0)), 0.0, 0.95)
	var duration_ticks: int = max(1, int(round(float(effect_def.get("duration", 0.0)) * float(tick_rate))))
	for index in range(entities.size()):
		var entity: Dictionary = entities[index]
		if not bool(entity.get("alive", false)):
			continue
		if str(entity.get("side", "")) != "enemy":
			continue
		var current_ratio: float = float(entity.get("slow_ratio", 0.0))
		var current_ticks: int = int(entity.get("slow_ticks_remaining", 0))
		entity["slow_ratio"] = maxf(current_ratio, ratio)
		entity["slow_ticks_remaining"] = maxi(current_ticks, duration_ticks)
		entities[index] = entity


func _apply_enemy_front_nuke(effect_def: Dictionary, state: Dictionary, entities: Array, tick_now: int) -> void:
	var target_index: int = _find_front_enemy_index(entities)
	if target_index < 0:
		return
	var target: Dictionary = entities[target_index]
	var damage: float = maxf(float(effect_def.get("damage", 0.0)), 0.0)
	var next_hp: float = maxf(0.0, float(target.get("hp", 0.0)) - damage)
	target["hp"] = next_hp
	if next_hp <= 0.0 and bool(target.get("alive", false)):
		target["alive"] = false
		_record_casualty(state, target)
		_record_unit_down_log(state, target, tick_now)
	entities[target_index] = target


func _find_front_enemy_index(entities: Array) -> int:
	var best_index: int = -1
	var best_x: float = INF
	for index in range(entities.size()):
		var entity: Dictionary = entities[index]
		if not bool(entity.get("alive", false)):
			continue
		if str(entity.get("side", "")) != "enemy":
			continue
		var x: float = _position_of(entity).x
		if x < best_x:
			best_x = x
			best_index = index
	return best_index


func _tick_status_effects(entities: Array) -> void:
	for index in range(entities.size()):
		var entity: Dictionary = entities[index]
		var slow_ticks: int = int(entity.get("slow_ticks_remaining", 0))
		if slow_ticks <= 0:
			continue
		slow_ticks -= 1
		entity["slow_ticks_remaining"] = slow_ticks
		if slow_ticks <= 0:
			entity["slow_ratio"] = 0.0
		entities[index] = entity


func _process_attacks(state: Dictionary, entities: Array, tick_now: int) -> void:
	var tick_rate: int = maxi(int(state.get("tick_rate", 10)), 1)
	for attacker_index in range(entities.size()):
		var attacker: Dictionary = entities[attacker_index]
		if not bool(attacker.get("alive", false)):
			continue
		var cooldown_ticks := int(attacker.get("attack_cooldown_ticks", 0))
		if cooldown_ticks > 0:
			attacker["attack_cooldown_ticks"] = cooldown_ticks - 1
			entities[attacker_index] = attacker
			continue
		var target_index: int = _find_nearest_opponent_index(attacker, entities)
		if target_index < 0:
			continue
		var target: Dictionary = entities[target_index]
		if not _is_in_attack_range(attacker, target):
			continue
		var damage: float = _effective_attack_power(attacker, state)
		if damage <= 0.0:
			attacker["attack_cooldown_ticks"] = _attack_interval_ticks(attacker, tick_rate)
			entities[attacker_index] = attacker
			continue
		var target_hp: float = maxf(0.0, float(target.get("hp", 0.0)) - damage)
		target["hp"] = target_hp
		if target_hp <= 0.0 and bool(target.get("alive", false)):
			target["alive"] = false
			_record_casualty(state, target)
			_record_unit_down_log(state, target, tick_now)
		attacker["attack_cooldown_ticks"] = _attack_interval_ticks(attacker, tick_rate)
		entities[attacker_index] = attacker
		entities[target_index] = target
	state["entities"] = entities


func _find_nearest_opponent_index(attacker: Dictionary, entities: Array) -> int:
	var attacker_side := str(attacker.get("side", ""))
	var attacker_pos := _position_of(attacker)
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


func _is_in_attack_range(attacker: Dictionary, target: Dictionary) -> bool:
	var range_value := maxf(float(attacker.get("attack_range", 0.0)), 0.0)
	return _position_of(attacker).distance_to(_position_of(target)) <= range_value


func _effective_attack_power(attacker: Dictionary, state: Dictionary) -> float:
	var attack_power := float(attacker.get("attack_power", 0.0))
	var attacker_side := str(attacker.get("side", ""))
	if attacker_side != "ally":
		return maxf(0.0, attack_power)
	var tags: Array = attacker.get("tags", [])
	for strategy_def in state.get("strategies", []):
		var effect_def: Dictionary = strategy_def.get("effect_def", {})
		if str(effect_def.get("type", "")) != ALLY_TAG_ATTACK_SHIFT:
			continue
		var match_tag: String = str(effect_def.get("tag", ""))
		var has_tag: bool = _array_has_string(tags, match_tag)
		if has_tag:
			attack_power += float(effect_def.get("bonus", 0.0))
		else:
			attack_power += float(effect_def.get("penalty", 0.0))
	return maxf(0.0, attack_power)


func _attack_interval_ticks(attacker: Dictionary, tick_rate: int) -> int:
	var attack_speed := maxf(float(attacker.get("attack_speed", 1.0)), 0.01)
	return max(1, int(round(float(tick_rate) / attack_speed)))


func _position_of(entity: Dictionary) -> Vector2:
	var position = entity.get("position", Vector2.ZERO)
	if position is Vector2:
		return position
	return Vector2.ZERO


func _is_same_team(side_a: String, side_b: String) -> bool:
	if side_a == "enemy":
		return side_b == "enemy"
	if side_b == "enemy":
		return false
	return true


func _array_has_string(values: Array, expected: String) -> bool:
	for value in values:
		if str(value) == expected:
			return true
	return false


func _record_unit_down_log(state: Dictionary, entity: Dictionary, tick_now: int) -> void:
	var side := str(entity.get("side", ""))
	var log_type := "unit_down"
	if side == "enemy":
		log_type = "enemy_down"
	elif side == "ally":
		log_type = "ally_down"
	elif side == "hero":
		log_type = "hero_down"
	state["log_entries"].append({
		"tick": tick_now,
		"type": log_type,
		"entity_id": str(entity.get("entity_id", ""))
	})


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

func _record_casualty(state: Dictionary, entity: Dictionary) -> void:
	var entity_id := str(entity.get("entity_id", ""))
	var casualties: Array = state.get("casualties", [])
	if entity_id in casualties:
		return
	casualties.append(entity_id)
	state["casualties"] = casualties
