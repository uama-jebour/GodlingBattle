extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return

	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{
			"tick": 0,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(240, 320)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 100.0, "max_hp": 100.0, "attack_range": 120.0, "position": Vector2(920, 320)}
			]
		},
		{
			"tick": 1,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 76.0, "max_hp": 100.0, "position": Vector2(240, 320)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 100.0, "max_hp": 100.0, "attack_range": 120.0, "position": Vector2(920, 320)}
			]
		}
	]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.call("_seek_to_frame", 1)

	if not screen.has_method("get_attack_line_count"):
		_failures.append("missing get_attack_line_count")
	elif int(screen.call("get_attack_line_count")) <= 0:
		_failures.append("enemy-side hp drop should still produce at least one inferred attack line")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
