extends SceneTree

const AI := preload("res://scripts/battle_runtime/battle_ai_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ai: RefCounted = AI.new()
	var state := {
		"tick_rate": 10,
		"entities": [
			{
				"entity_id": "ally_0",
				"side": "ally",
				"alive": true,
				"hp": 20.0,
				"max_hp": 100.0,
				"attack_range": 70.0,
				"base_move_speed": 120.0,
				"move_speed": 120.0,
				"position": Vector2(300.0, 300.0),
				"recent_damage_pressure": 1.0
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"hp": 100.0,
				"max_hp": 100.0,
				"attack_range": 100.0,
				"base_move_speed": 100.0,
				"move_speed": 100.0,
				"position": Vector2(340.0, 300.0)
			},
			{
				"entity_id": "enemy_1",
				"side": "enemy",
				"alive": true,
				"hp": 100.0,
				"max_hp": 100.0,
				"attack_range": 100.0,
				"base_move_speed": 100.0,
				"move_speed": 100.0,
				"position": Vector2(340.0, 340.0)
			}
		]
	}

	var start := ((state["entities"] as Array)[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	for _i in range(8):
		ai.tick(state)
	var entities: Array = state.get("entities", [])
	var finish := (entities[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	if finish.distance_to(start) < 20.0:
		_failures.append("expected breakout displacement under pressure")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
