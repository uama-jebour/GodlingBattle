extends RefCounted

const STATE := preload("res://scripts/battle_runtime/battle_state.gd")
const AI := preload("res://scripts/battle_runtime/battle_ai_system.gd")
const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")
const EVENTS := preload("res://scripts/battle_runtime/battle_event_response_system.gd")

var _state := STATE.new()
var _ai := AI.new()
var _combat := COMBAT.new()
var _events := EVENTS.new()


func run(setup: Dictionary) -> Dictionary:
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
