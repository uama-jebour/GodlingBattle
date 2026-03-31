extends SceneTree

const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var combat: RefCounted = COMBAT.new()
	var state := {
		"tick_rate": 10,
		"elapsed_ticks": 0,
		"entities": [
			{
				"entity_id": "hero_0",
				"side": "hero",
				"alive": true,
				"hp": 100.0,
				"max_hp": 100.0,
				"attack_power": 0.0,
				"attack_speed": 1.0,
				"attack_range": 1.0,
				"position": Vector2(0.0, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": []
			},
			{
				"entity_id": "ally_0",
				"side": "ally",
				"alive": true,
				"hp": 20.0,
				"max_hp": 20.0,
				"attack_power": 0.0,
				"attack_speed": 1.0,
				"attack_range": 1.0,
				"position": Vector2(0.0, 80.0),
				"attack_cooldown_ticks": 0,
				"tags": ["虚无"]
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"hp": 30.0,
				"max_hp": 30.0,
				"attack_power": 0.0,
				"attack_speed": 1.0,
				"attack_range": 1.0,
				"position": Vector2(800.0, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": []
			}
		],
		"strategies": [
			{
				"strategy_id": "strat_void_echo",
				"trigger_def": {"type": "always_on"},
				"effect_def": {
					"type": "ally_tag_attack_shift",
					"tag": "虚无",
					"bonus": 3.0,
					"penalty": -3.0
				}
			}
		],
		"triggered_strategies": [],
		"log_entries": [],
		"casualties": [],
		"completed": false
	}

	combat.tick(state)
	state["elapsed_ticks"] = 1
	combat.tick(state)

	var triggered_rows: Array = state.get("triggered_strategies", [])
	var passive_cast_logs: Array = _strategy_logs(state.get("log_entries", []), "strat_void_echo")
	if triggered_rows.size() != 1:
		_failures.append("expected always_on strategy to be recorded once, got %d" % triggered_rows.size())
	if passive_cast_logs.size() != 1:
		_failures.append("expected passive strategy_cast log once, got %d" % passive_cast_logs.size())
	elif str((passive_cast_logs[0] as Dictionary).get("cast_mode", "")) != "passive":
		_failures.append("expected passive strategy_cast log to carry cast_mode=passive")

	_finish()


func _strategy_logs(rows: Array, strategy_id: String) -> Array:
	var filtered: Array = []
	for row in rows:
		if str(row.get("type", "")) != "strategy_cast":
			continue
		if str(row.get("strategy_id", "")) != strategy_id:
			continue
		filtered.append(row)
	return filtered


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
