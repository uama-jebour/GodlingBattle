extends SceneTree

var _failures: Array[String] = []
const _EPS := 0.001


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	screen.size = Vector2(1280, 720)
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
	screen.update_hud_for_tick(12, [])
	screen._ensure_map()

	if int(screen.get_layer_child_count("ally")) != 1:
		_failures.append("expected ally layer count = 1")
	if int(screen.get_layer_child_count("enemy")) != 1:
		_failures.append("expected enemy layer count = 1")
	if str(screen.get_token_parent_name("enemy_1")) != "EnemyLayer":
		_failures.append("enemy token should mount under EnemyLayer")
	if screen.get_node_or_null("TokenHost") == null:
		_failures.append("fallback should mount TokenHost for script-only usage")
	if screen.get_node_or_null("HudRoot") == null:
		_failures.append("fallback should mount HudRoot for script-only usage")
	if screen.get_node_or_null("BattleMap") == null:
		_failures.append("fallback should mount BattleMap for script-only usage")

	var layout_root := Control.new()
	layout_root.name = "LayoutRoot"
	screen.add_child(layout_root)
	var left_column := Control.new()
	left_column.name = "LeftColumn"
	layout_root.add_child(left_column)
	var battlefield_panel := Control.new()
	battlefield_panel.name = "BattlefieldPanel"
	battlefield_panel.position = Vector2(80, 40)
	battlefield_panel.size = Vector2(960, 520)
	left_column.add_child(battlefield_panel)
	var battlefield_runtime := Control.new()
	battlefield_runtime.name = "BattlefieldRuntime"
	battlefield_runtime.size = battlefield_panel.size
	battlefield_panel.add_child(battlefield_runtime)
	var battlefield_hint := Label.new()
	battlefield_hint.name = "BattlefieldHint"
	battlefield_panel.add_child(battlefield_hint)

	screen.sync_token_views([
		{"entity_id": "hero_1", "display_name": "英雄", "side": "hero", "hp_ratio": 0.9, "position": Vector2(130, 230)},
		{"entity_id": "enemy_1", "display_name": "敌方", "side": "enemy", "hp_ratio": 0.7, "position": Vector2(530, 230)}
	])
	screen.update_hud_for_tick(13, [])
	screen._ensure_map()
	if screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/TokenHost") == null:
		_failures.append("TokenHost should recover under BattlefieldPanel when it becomes available")
	if screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot") == null:
		_failures.append("HudRoot should recover under BattlefieldPanel when it becomes available")
	if screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/BattleMap") == null:
		_failures.append("BattleMap should recover under BattlefieldPanel when it becomes available")
	var recovered_token_host := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/TokenHost") as Control
	var recovered_hud_root := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot") as Control
	var recovered_battle_map := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/BattleMap") as Control
	_assert_full_rect(recovered_token_host, "TokenHost")
	_assert_full_rect(recovered_hud_root, "HudRoot")
	_assert_full_rect(recovered_battle_map, "BattleMap")
	if recovered_battle_map != null and recovered_token_host != null and recovered_hud_root != null:
		if recovered_battle_map.get_index() >= recovered_token_host.get_index():
			_failures.append("BattleMap should remain below TokenHost after recovery")
		if recovered_token_host.get_index() >= recovered_hud_root.get_index():
			_failures.append("TokenHost should remain below HudRoot after recovery")
	var recovered_hud_bg := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/HudBg") as ColorRect
	var recovered_tick_label := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/TickLabel") as Label
	var recovered_event_label := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/EventLabel") as Label
	var recovered_strategy_label := screen.get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime/HudRoot/StrategyCastLabel") as Label
	if recovered_hud_bg == null:
		_failures.append("missing HudBg after recovery")
	elif recovered_hud_bg.size.y > 80.0:
		_failures.append("HudBg should be compact single-line height (<=80)")
	if recovered_tick_label == null or recovered_event_label == null or recovered_strategy_label == null:
		_failures.append("missing hud labels after recovery")
	else:
		if absf(recovered_event_label.position.y - recovered_strategy_label.position.y) > 4.0:
			_failures.append("event and strategy labels should stay on one line")
		if recovered_tick_label.position.y > recovered_event_label.position.y + 6.0:
			_failures.append("tick label should align on one line with event labels")
	if screen.get_node_or_null("TokenHost") != null:
		_failures.append("TokenHost should not stay on screen root after BattlefieldPanel recovery")
	if screen.get_node_or_null("HudRoot") != null:
		_failures.append("HudRoot should not stay on screen root after BattlefieldPanel recovery")
	if screen.get_node_or_null("BattleMap") != null:
		_failures.append("BattleMap should not stay on screen root after BattlefieldPanel recovery")
	if battlefield_hint.visible:
		_failures.append("BattlefieldHint should hide once battlefield host is active")

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


func _assert_full_rect(control: Control, label: String) -> void:
	if control == null:
		return
	if absf(control.anchor_left) > _EPS:
		_failures.append("%s anchor_left should be 0 after recovery" % label)
	if absf(control.anchor_top) > _EPS:
		_failures.append("%s anchor_top should be 0 after recovery" % label)
	if absf(control.anchor_right - 1.0) > _EPS:
		_failures.append("%s anchor_right should be 1 after recovery" % label)
	if absf(control.anchor_bottom - 1.0) > _EPS:
		_failures.append("%s anchor_bottom should be 1 after recovery" % label)
	if absf(control.offset_left) > _EPS:
		_failures.append("%s offset_left should be 0 after recovery" % label)
	if absf(control.offset_top) > _EPS:
		_failures.append("%s offset_top should be 0 after recovery" % label)
	if absf(control.offset_right) > _EPS:
		_failures.append("%s offset_right should be 0 after recovery" % label)
	if absf(control.offset_bottom) > _EPS:
		_failures.append("%s offset_bottom should be 0 after recovery" % label)


func _finish(screen: Control) -> void:
	screen.free()
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
