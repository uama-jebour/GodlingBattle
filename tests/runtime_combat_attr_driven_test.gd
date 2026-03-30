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
				"attack_power": 5.0,
				"attack_speed": 1.5,
				"attack_range": 4.0,
				"position": Vector2(0.0, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": []
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
				"position": Vector2(2.0, 0.0),
				"attack_cooldown_ticks": 0,
				"tags": []
			}
		],
		"strategies": [],
		"log_entries": [],
		"casualties": [],
		"completed": false
	}

	combat.tick(state)
	var entities: Array = state.get("entities", [])
	var enemy_after_first: Dictionary = entities[1]
	if not is_equal_approx(float(enemy_after_first.get("hp", 0.0)), 25.0):
		_failures.append("expected enemy hp 25.0 after first attack")

	state["elapsed_ticks"] = 1
	combat.tick(state)
	entities = state.get("entities", [])
	var enemy_after_second: Dictionary = entities[1]
	if not is_equal_approx(float(enemy_after_second.get("hp", 0.0)), 25.0):
		_failures.append("expected cooldown to block second immediate attack")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
