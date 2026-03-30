extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	assert(session_state != null)
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var battlefield_panel := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel")
	assert(battlefield_panel != null)
	var battle_map := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattleMap")
	assert(battle_map != null)
	var token_host := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/TokenHost")
	var hud_root := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/HudRoot")
	assert(token_host != null)
	assert(hud_root != null)
	assert(battle_map.get_index() < token_host.get_index())
	assert(token_host.get_index() < hud_root.get_index())

	screen.queue_free()
	await process_frame
	quit(0)
