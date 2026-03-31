extends SceneTree

const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var combat: RefCounted = COMBAT.new()
	var state := {
		"tick_rate": 10,
		"elapsed_ticks": 1,
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
				"tags": []
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
				"position": Vector2(600.0, 0.0),
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
	var ally := entities[1] as Dictionary
	if not is_equal_approx(float(ally.get("hp", 0.0)), 20.0):
		_failures.append("ally hp should not drop without real attacks (hp=%s)" % [ally.get("hp", 0.0)])

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
