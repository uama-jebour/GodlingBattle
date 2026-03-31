extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()

	var unmatched_payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	_assert_warning_has_response_hint(
		unmatched_payload.get("result", {}).get("log_entries", []),
		"evt_hunter_fiend_arrival",
		false
	)

	var matched_payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_counter_demon_summon"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	_assert_warning_has_response_hint(
		matched_payload.get("result", {}).get("log_entries", []),
		"evt_hunter_fiend_arrival",
		true
	)

	_finish()


func _assert_warning_has_response_hint(rows: Array, event_id: String, expect_ready: bool) -> void:
	for row in rows:
		if str(row.get("type", "")) != "event_warning":
			continue
		if str(row.get("event_id", "")) != event_id:
			continue
		var response_ready := bool(row.get("response_ready", not expect_ready))
		if response_ready != expect_ready:
			_failures.append("warning response_ready mismatch for %s (expected %s)" % [event_id, expect_ready])
		var strategy_id := str(row.get("response_strategy_id", ""))
		if expect_ready:
			if strategy_id != "strat_counter_demon_summon":
				_failures.append("expected matched response strategy id for %s" % event_id)
		else:
			if strategy_id != "":
				_failures.append("expected empty response strategy id when unmatched for %s" % event_id)
			if str(row.get("response_missing_reason", "")).is_empty():
				_failures.append("expected response_missing_reason when unmatched for %s" % event_id)
		return
	_failures.append("missing warning row for %s" % event_id)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
