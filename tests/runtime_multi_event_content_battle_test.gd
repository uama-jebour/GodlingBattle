extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	var battle_beta: Dictionary = content.get_battle("battle_void_gate_beta")
	if battle_beta.is_empty():
		_failures.append("battle_void_gate_beta should exist")
	content.free()
	if not _failures.is_empty():
		_finish()
		return

	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_counter_demon_summon"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	})
	var result: Dictionary = payload.get("result", {})
	var logs: Array = result.get("log_entries", [])
	var triggered_events: Array = result.get("triggered_events", [])

	_expect_event_logs(logs, "evt_demon_ambush")
	_expect_event_logs(logs, "evt_void_collapse")
	if triggered_events.size() < 2:
		_failures.append("expected at least 2 triggered events in beta battle")

	var has_unresolved := false
	for row in logs:
		if str(row.get("type", "")) == "event_unresolved_effect":
			has_unresolved = true
			break
	if not has_unresolved:
		_failures.append("expected unresolved effect for at least one event in beta battle")

	_finish()


func _expect_event_logs(logs: Array, event_id: String) -> void:
	var has_warning := false
	var has_resolve := false
	for row in logs:
		if str(row.get("event_id", "")) != event_id:
			continue
		if str(row.get("type", "")) == "event_warning":
			has_warning = true
		elif str(row.get("type", "")) == "event_resolve":
			has_resolve = true
	if not has_warning:
		_failures.append("missing warning log for %s" % event_id)
	if not has_resolve:
		_failures.append("missing resolve log for %s" % event_id)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
