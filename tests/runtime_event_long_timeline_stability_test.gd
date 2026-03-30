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
			{"entity_id": "ally_0", "side": "ally", "hp": 50.0, "max_hp": 50.0, "alive": true}
		],
		"events": [
			{
				"event_id": "evt_long_alpha",
				"trigger_def": {"type": "elapsed_gte", "value": 1.0},
				"warning_seconds": 200.0,
				"response_tag": "long_response",
				"response_level": 1
			},
			{
				"event_id": "evt_long_beta",
				"trigger_def": {"type": "elapsed_gte", "value": 100.0},
				"warning_seconds": 300.0,
				"response_tag": "long_response",
				"response_level": 1
			}
		],
		"strategies": [
			{"strategy_id": "strat_long_guard", "trigger_def": {"type": "event_response", "response_tag": "long_response", "response_level": 1}}
		],
		"log_entries": [],
		"triggered_events": [],
		"triggered_strategies": []
	}

	for tick in range(6000):
		state["elapsed_ticks"] = tick
		events.tick(state)

	_assert_single_warning_and_resolve(state, "evt_long_alpha")
	_assert_single_warning_and_resolve(state, "evt_long_beta")

	var runtime: Dictionary = state.get("event_runtime", {})
	if str(runtime.get("evt_long_alpha", {}).get("stage", "")) != "done":
		_failures.append("evt_long_alpha should be done")
	if str(runtime.get("evt_long_beta", {}).get("stage", "")) != "done":
		_failures.append("evt_long_beta should be done")

	var logs: Array = state.get("log_entries", [])
	if logs.size() > 8:
		_failures.append("log entries should remain compact in long timeline, got %d" % logs.size())

	_finish()


func _assert_single_warning_and_resolve(state: Dictionary, event_id: String) -> void:
	var warnings := _count_event_log(state.get("log_entries", []), "event_warning", event_id)
	var resolves := _count_event_log(state.get("log_entries", []), "event_resolve", event_id)
	if warnings != 1:
		_failures.append("expected 1 warning for %s, got %d" % [event_id, warnings])
	if resolves != 1:
		_failures.append("expected 1 resolve for %s, got %d" % [event_id, resolves])


func _count_event_log(logs: Array, log_type: String, event_id: String) -> int:
	var count := 0
	for row in logs:
		if str(row.get("type", "")) != log_type:
			continue
		if str(row.get("event_id", "")) != event_id:
			continue
		count += 1
	return count


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
