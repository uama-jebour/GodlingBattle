extends RefCounted

const STATE := preload("res://scripts/battle_runtime/battle_state.gd")
const AI := preload("res://scripts/battle_runtime/battle_ai_system.gd")
const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")
const EVENTS := preload("res://scripts/battle_runtime/battle_event_response_system.gd")
const CONTENT := preload("res://autoload/battle_content.gd")
const MIN_ALLY_COUNT := 0
const MAX_ALLY_COUNT := 8

var _state := STATE.new()
var _ai := AI.new()
var _combat := COMBAT.new()
var _events := EVENTS.new()


func run(setup: Dictionary) -> Dictionary:
	var invalid_reason := _validate_setup(setup)
	if not invalid_reason.is_empty():
		return _build_invalid_payload(invalid_reason)

	var state := _state.initialize(setup)
	var timeline: Array = []
	while not bool(state.get("completed", false)):
		_ai.tick(state)
		_combat.tick(state)
		_events.tick(state)
		timeline.append({
			"tick": state["elapsed_ticks"],
			"entities": state.get("entities", []).duplicate(true)
		})
		state["elapsed_ticks"] = int(state.get("elapsed_ticks", 0)) + 1
		if int(state["elapsed_ticks"]) >= int(state["max_ticks"]):
			state["completed"] = true

	var entities: Array = state.get("entities", [])
	var hero_alive := false
	var enemy_alive := false
	var survivors: Array = []
	for entity in entities:
		var alive := bool(entity.get("alive", false))
		if not alive:
			continue
		survivors.append(String(entity.get("entity_id", "")))
		var side := String(entity.get("side", ""))
		if side == "hero":
			hero_alive = true
		elif side == "enemy":
			enemy_alive = true

	var victory := false
	var defeat_reason := "timeout"
	var status := "completed"
	if not hero_alive:
		victory = false
		defeat_reason = "hero_dead"
	elif not enemy_alive:
		victory = true
		defeat_reason = ""
	elif int(state["elapsed_ticks"]) >= int(state["max_ticks"]):
		victory = false
		defeat_reason = "timeout"
	else:
		victory = false
		defeat_reason = "unknown"

	return {
		"timeline": timeline,
		"result": {
			"status": status,
			"victory": victory,
			"defeat_reason": defeat_reason,
			"elapsed_seconds": float(state["elapsed_ticks"]) / float(state["tick_rate"]),
			"survivors": survivors,
			"casualties": state.get("casualties", []).duplicate(true),
			"triggered_events": state.get("triggered_events", []).duplicate(true),
			"triggered_strategies": state.get("triggered_strategies", []).duplicate(true),
			"log_entries": state.get("log_entries", []).duplicate(true)
		}
	}


func _validate_setup(setup: Dictionary) -> String:
	var content: Node = CONTENT.new()
	var hero_id := str(setup.get("hero_id", ""))
	if hero_id.is_empty() or content.get_unit(hero_id).is_empty():
		content.free()
		return "missing_hero"
	var ally_entries: Array = setup.get("ally_entries", [])
	if not ally_entries.is_empty():
		var total := 0
		for raw in ally_entries:
			var entry := raw as Dictionary
			var unit_id := str(entry.get("unit_id", ""))
			var count := int(entry.get("count", 0))
			if unit_id.is_empty() or count <= 0:
				content.free()
				return "invalid_ally_count"
			if content.get_unit(unit_id).is_empty():
				content.free()
				return "missing_ally"
			total += count
		if total < MIN_ALLY_COUNT or total > MAX_ALLY_COUNT:
			content.free()
			return "invalid_ally_count"
	else:
		var ally_ids: Array = setup.get("ally_ids", [])
		if ally_ids.size() < MIN_ALLY_COUNT or ally_ids.size() > MAX_ALLY_COUNT:
			content.free()
			return "invalid_ally_count"
		for ally_id in ally_ids:
			if content.get_unit(str(ally_id)).is_empty():
				content.free()
				return "missing_ally"
	for strategy_id in setup.get("strategy_ids", []):
		if content.get_strategy(str(strategy_id)).is_empty():
			content.free()
			return "missing_strategy"
	var battle_id := str(setup.get("battle_id", ""))
	if battle_id.is_empty() or content.get_battle(battle_id).is_empty():
		content.free()
		return "missing_battle"
	content.free()
	return ""


func _build_invalid_payload(reason: String) -> Dictionary:
	return {
		"timeline": [],
		"result": {
			"status": "invalid_setup",
			"victory": false,
			"defeat_reason": reason,
			"elapsed_seconds": 0.0,
			"survivors": [],
			"casualties": [],
			"triggered_events": [],
			"triggered_strategies": [],
			"log_entries": []
		}
	}
