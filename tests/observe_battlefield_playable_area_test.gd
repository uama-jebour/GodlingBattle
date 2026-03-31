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
	session_state.last_timeline = [{
		"tick": 0,
		"entities": [
			{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(120, 220)},
			{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "alive": true, "hp": 100.0, "max_hp": 100.0, "position": Vector2(520, 220)}
		]
	}]
	session_state.last_battle_result = {"log_entries": []}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var battle_map := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/BattleMap") as Control
	if battle_map == null:
		_failures.append("missing BattleMap")
	else:
		var map_rect := battle_map.get_rect()
		if map_rect.size.y <= 0.0:
			_failures.append("battle map height should be positive (rect=%s)" % map_rect)
		var playable := Rect2(Vector2(96, 96), map_rect.size - Vector2(192, 192))
		if battle_map.has_method("get_playable_bounds"):
			playable = battle_map.call("get_playable_bounds")
		if playable.size.x <= 0.0 or playable.size.y <= 0.0:
			_failures.append("playable rect should be valid (playable=%s map=%s)" % [playable, map_rect])
		var hero_token := screen.call("get_token_view", "hero_1") as Control
		if hero_token == null:
			_failures.append("missing hero token")
		elif playable.size.x > 0.0 and playable.size.y > 0.0:
			if not playable.has_point(hero_token.position):
				_failures.append("hero token should stay in playable area (token=%s playable=%s)" % [hero_token.position, playable])
		var hud_bg := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/HudBg") as ColorRect
		if hud_bg != null and hero_token != null:
			var hud_bottom := hud_bg.position.y + hud_bg.size.y
			if hero_token.position.y < hud_bottom + 8.0:
				_failures.append("hero token should stay below hud band (token_y=%f hud_bottom=%f)" % [hero_token.position.y, hud_bottom])

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
