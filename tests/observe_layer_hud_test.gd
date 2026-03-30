extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	if not screen.has_method("get_layer_child_count"):
		_failures.append("missing get_layer_child_count")
		_finish(screen)
		return
	if not screen.has_method("get_token_parent_name"):
		_failures.append("missing get_token_parent_name")
		_finish(screen)
		return
	if not screen.has_method("update_hud_for_tick"):
		_failures.append("missing update_hud_for_tick")
		_finish(screen)
		return
	if not screen.has_method("get_tick_text"):
		_failures.append("missing get_tick_text")
		_finish(screen)
		return
	if not screen.has_method("get_event_text"):
		_failures.append("missing get_event_text")
		_finish(screen)
		return
	if not screen.has_method("get_strategy_cast_text"):
		_failures.append("missing get_strategy_cast_text")
		_finish(screen)
		return

	screen.sync_token_views([
		{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "hp_ratio": 1.0, "position": Vector2(120, 220)},
		{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "hp_ratio": 1.0, "position": Vector2(540, 220)}
	])

	if int(screen.get_layer_child_count("ally")) != 1:
		_failures.append("expected ally layer count = 1")
	if int(screen.get_layer_child_count("enemy")) != 1:
		_failures.append("expected enemy layer count = 1")
	if str(screen.get_token_parent_name("enemy_1")) != "EnemyLayer":
		_failures.append("enemy token should mount under EnemyLayer")

	screen.update_hud_for_tick(12, [{
		"type": "event_warning",
		"tick": 12,
		"event_id": "evt_hunter_fiend_arrival"
	}, {
		"type": "strategy_cast",
		"tick": 12,
		"strategy_id": "strat_chill_wave"
	}])
	if str(screen.get_tick_text()) != "第12帧":
		_failures.append("unexpected tick text")
	if str(screen.get_event_text()).find("事件预警") == -1:
		_failures.append("missing event hint text")
	if str(screen.get_event_text()).find("event_warning") != -1:
		_failures.append("event text should not expose english event type")
	if str(screen.get_strategy_cast_text()).find("寒潮冲击") == -1:
		_failures.append("missing strategy cast text")
	if str(screen.get_strategy_cast_text()).find("strat_chill_wave") != -1:
		_failures.append("strategy text should not expose strategy id")

	_finish(screen)


func _finish(screen: Control) -> void:
	screen.free()
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
