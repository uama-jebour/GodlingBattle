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
				"entity_id": "hero_0",
				"side": "hero",
				"alive": true,
				"position": Vector2(0.0, 0.0),
				"attack_range": 80.0,
				"base_move_speed": 120.0,
				"move_speed": 120.0
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"position": Vector2(420.0, 0.0),
				"attack_range": 80.0,
				"base_move_speed": 120.0,
				"move_speed": 120.0
			}
		]
	}

	var initial_entities: Array = state.get("entities", [])
	var hero_initial := (initial_entities[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	var enemy_initial := (initial_entities[1] as Dictionary).get("position", Vector2.ZERO) as Vector2
	for _i in range(20):
		ai.tick(state)

	var moved_entities: Array = state.get("entities", [])
	var hero_now := (moved_entities[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	var enemy_now := (moved_entities[1] as Dictionary).get("position", Vector2.ZERO) as Vector2

	if hero_now.x <= hero_initial.x:
		_failures.append("hero should advance toward enemy along x axis")
	if enemy_now.x >= enemy_initial.x:
		_failures.append("enemy should advance toward hero along x axis")
	if absf(hero_now.y - hero_initial.y) < 0.1 and absf(enemy_now.y - enemy_initial.y) < 0.1:
		_failures.append("at least one unit should produce lateral movement for flank pathing")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
