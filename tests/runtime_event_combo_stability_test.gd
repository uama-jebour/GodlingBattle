extends SceneTree

const EVENT_SYSTEM := preload("res://scripts/battle_runtime/battle_event_response_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var events: RefCounted = EVENT_SYSTEM.new()
	var state := {
		"tick_rate": 10,
		"elapsed_ticks": 0,
		"entities": [
			{"entity_id": "ally_0", "side": "ally", "hp": 20.0, "max_hp": 20.0, "alive": true},
			{"entity_id": "ally_1", "side": "ally", "hp": 20.0, "max_hp": 20.0, "alive": true}
		],
		"events": [
			{
				"event_id": "evt_combo_alpha",
				"trigger_def": {"type": "elapsed_gte", "value": 1.0},
				"warning_seconds": 0.5,
				"response_tag": "恶魔召唤",
				"response_level": 1
			},
			{
				"event_id": "evt_combo_beta",
				"trigger_def": {"type": "any", "rules": [{"type": "elapsed_gte", "value": 2.0}, {"type": "ally_hp_ratio_lte", "value": 0.6}]},
				"warning_seconds": 1.0,
				"response_tag": "恶魔召唤",
				"response_level": 1
			},
			{
				"event_id": "evt_combo_gamma",
				"trigger_def": {"type": "ally_hp_ratio_lte", "value": 0.3},
				"warning_seconds": 1.5,
				"response_tag": "崩解防护",
				"response_level": 2
			}
		],
		"strategies": [
			{"strategy_id": "strat_counter_demon_summon", "trigger_def": {"type": "event_response", "response_tag": "恶魔召唤", "response_level": 1}},
			{"strategy_id": "strat_collapse_guard", "trigger_def": {"type": "event_response", "response_tag": "崩解防护", "response_level": 2}}
		],
		"log_entries": [],
		"triggered_events": [],
		"triggered_strategies": []
	}

	for tick in range(200):
		state["elapsed_ticks"] = tick
		_decay_ally_hp(state, tick)
		events.tick(state)

	_assert_single_warning_and_resolve(state, "evt_combo_alpha")
	_assert_single_warning_and_resolve(state, "evt_combo_beta")
	_assert_single_warning_and_resolve(state, "evt_combo_gamma")

	var unresolved_count := _count_log_type(state.get("log_entries", []), "event_unresolved_effect")
	if unresolved_count != 0:
		_failures.append("expected no unresolved event effect, got %d" % unresolved_count)

	var triggered_events: Array = state.get("triggered_events", [])
	if triggered_events.size() != 3:
		_failures.append("expected 3 triggered events, got %d" % triggered_events.size())

	var triggered_strategies: Array = state.get("triggered_strategies", [])
	if triggered_strategies.size() != 3:
		_failures.append("expected 3 triggered strategies, got %d" % triggered_strategies.size())

	_finish()


func _decay_ally_hp(state: Dictionary, tick: int) -> void:
	if tick % 4 != 0:
		return
	var entities: Array = state.get("entities", [])
	if entities.is_empty():
		return
	var ally: Dictionary = entities[0]
	var next_hp := maxf(0.0, float(ally.get("hp", 0.0)) - 1.0)
	ally["hp"] = next_hp
	entities[0] = ally
	state["entities"] = entities


func _assert_single_warning_and_resolve(state: Dictionary, event_id: String) -> void:
	var warnings := _count_event_log(state.get("log_entries", []), "event_warning", event_id)
	var resolves := _count_event_log(state.get("log_entries", []), "event_resolve", event_id)
	if warnings != 1:
		_failures.append("expected 1 warning for %s, got %d" % [event_id, warnings])
	if resolves != 1:
		_failures.append("expected 1 resolve for %s, got %d" % [event_id, resolves])
	var warning_tick := _event_tick(state.get("log_entries", []), "event_warning", event_id)
	var resolve_tick := _event_tick(state.get("log_entries", []), "event_resolve", event_id)
	if warning_tick < 0 or resolve_tick <= warning_tick:
		_failures.append("expected warning tick < resolve tick for %s" % event_id)


func _count_event_log(logs: Array, log_type: String, event_id: String) -> int:
	var count := 0
	for row in logs:
		if str(row.get("type", "")) != log_type:
			continue
		if str(row.get("event_id", "")) != event_id:
			continue
		count += 1
	return count


func _count_log_type(logs: Array, log_type: String) -> int:
	var count := 0
	for row in logs:
		if str(row.get("type", "")) == log_type:
			count += 1
	return count


func _event_tick(logs: Array, log_type: String, event_id: String) -> int:
	for row in logs:
		if str(row.get("type", "")) != log_type:
			continue
		if str(row.get("event_id", "")) != event_id:
			continue
		return int(row.get("tick", -1))
	return -1


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
