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
		"strategy_ids": ["strat_counter_demon_summon"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [
		{
			"tick": 0,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(240, 260)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(680, 260)}
			]
		},
		{
			"tick": 1,
			"entities": [
				{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(245, 260)},
				{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 98.0, "max_hp": 100.0, "position": Vector2(672, 260)}
			]
		}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 1, "type": "event_resolve", "event_id": "evt_hunter_fiend_arrival", "responded": true}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.call("_seek_to_frame", 1)

	if not screen.has_method("get_event_response_indicator_count"):
		_failures.append("missing get_event_response_indicator_count")
	elif int(screen.call("get_event_response_indicator_count")) <= 0:
		_failures.append("expected event response indicator lines for responded event_resolve")

	if not screen.has_method("get_event_response_seal_count"):
		_failures.append("missing get_event_response_seal_count")
	elif int(screen.call("get_event_response_seal_count")) <= 0:
		_failures.append("expected seal_x variant for responded event indicator")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
