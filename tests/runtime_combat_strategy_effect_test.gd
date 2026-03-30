extends SceneTree

const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var combat: RefCounted = COMBAT.new()
	var base_state := _build_state([])
	combat.tick(base_state)
	var enemy_hp_without_strategy := float((base_state.get("entities", [])[1] as Dictionary).get("hp", 0.0))

	var buffed_state := _build_state([{
		"strategy_id": "strat_void_echo",
		"effect_def": {"type": "ally_tag_attack_shift", "tag": "虚无", "bonus": 5.0, "penalty": -5.0}
	}])
	combat.tick(buffed_state)
	var enemy_hp_with_strategy := float((buffed_state.get("entities", [])[1] as Dictionary).get("hp", 0.0))

	if not is_equal_approx(enemy_hp_without_strategy, 28.0):
		_failures.append("expected enemy hp 28.0 without strategy")
	if not is_equal_approx(enemy_hp_with_strategy, 23.0):
		_failures.append("expected enemy hp 23.0 with void echo strategy")

	_finish()


func _build_state(strategies: Array) -> Dictionary:
	return {
		"tick_rate": 10,
		"elapsed_ticks": 0,
		"entities": [
			{
				"entity_id": "ally_0",
				"side": "ally",
				"alive": true,
				"hp": 20.0,
				"max_hp": 20.0,
				"attack_power": 2.0,
				"attack_speed": 1.5,
				"attack_range": 1.0,
				"position": Vector2(0.0, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": ["虚无"]
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"hp": 30.0,
				"max_hp": 30.0,
				"attack_power": 3.0,
				"attack_speed": 1.0,
				"attack_range": 1.0,
				"position": Vector2(0.5, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": []
			}
		],
		"strategies": strategies,
		"log_entries": [],
		"casualties": [],
		"completed": false
	}


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
