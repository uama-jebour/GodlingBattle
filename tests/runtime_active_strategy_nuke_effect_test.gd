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
				"attack_range": 0.0,
				"position": Vector2(0.0, 0.0),
				"base_move_speed": 0.0,
				"move_speed": 0.0,
				"attack_cooldown_ticks": 0,
				"tags": [],
				"slow_ratio": 0.0,
				"slow_ticks_remaining": 0
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"hp": 15.0,
				"max_hp": 15.0,
				"attack_power": 0.0,
				"attack_speed": 1.0,
				"attack_range": 0.0,
				"position": Vector2(1.0, 0.0),
				"base_move_speed": 0.0,
				"move_speed": 0.0,
				"attack_cooldown_ticks": 0,
				"tags": [],
				"slow_ratio": 0.0,
				"slow_ticks_remaining": 0
			}
		],
		"strategies": [
			{
				"strategy_id": "strat_nuclear_strike",
				"trigger_def": {"type": "cooldown"},
				"cooldown": 25.0,
				"effect_def": {"type": "enemy_front_nuke", "damage": 20.0}
			}
		],
		"log_entries": [],
		"casualties": [],
		"triggered_strategies": [],
		"completed": false
	}

	combat.tick(state)
	var entities: Array = state.get("entities", [])
	var enemy_after_cast: Dictionary = entities[1]
	if bool(enemy_after_cast.get("alive", true)):
		_failures.append("expected enemy to die after nuclear strike")
	var triggered_count_after_first := _trigger_count(state.get("triggered_strategies", []), "strat_nuclear_strike")
	if triggered_count_after_first != 1:
		_failures.append("expected first nuclear trigger count 1")

	state["elapsed_ticks"] = 1
	combat.tick(state)
	var triggered_count_after_second := _trigger_count(state.get("triggered_strategies", []), "strat_nuclear_strike")
	if triggered_count_after_second != 1:
		_failures.append("expected cooldown to block immediate second nuclear trigger")

	_finish()


func _trigger_count(rows: Array, strategy_id: String) -> int:
	var count := 0
	for row in rows:
		if str(row.get("strategy_id", "")) == strategy_id:
			count += 1
	return count


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
