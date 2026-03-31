extends SceneTree

const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify_formatter_output()
	await _verify_observe_detail_toggle()
	_finish()


func _verify_formatter_output() -> void:
	var formatter_script := load("res://scripts/observe/battle_report_formatter.gd")
	if formatter_script == null:
		_failures.append("missing battle_report_formatter.gd")
		return
	var formatter: RefCounted = formatter_script.new()
	var rows := [
		{"tick": 8, "type": "strategy_cast", "strategy_id": "strat_void_echo", "cast_mode": "passive"},
		{"tick": 8, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
		{
			"tick": 8,
			"type": "event_warning",
			"event_id": "evt_hunter_fiend_arrival",
			"response_ready": false,
			"response_strategy_id": "",
			"response_missing_reason": "未携带对应对策"
		},
		{"tick": 8, "type": "event_resolve", "event_id": "evt_hunter_fiend_arrival", "responded": true},
		{"tick": 8, "type": "event_unresolved_effect", "event_id": "evt_hunter_fiend_arrival"},
		{"tick": 8, "type": "ally_down", "entity_id": "ally_hound_remnant_1"},
		{"tick": 8, "type": "hero_down", "entity_id": "hero_angel_0"},
		{"tick": 8, "type": "enemy_down", "entity_id": "enemy_wandering_demon_4"}
	]

	var brief_text := String(formatter.call("build_tick_brief", rows, 8, "all"))
	if brief_text.find("第8帧") == -1:
		_failures.append("brief text should include tick")
	if brief_text.find("寒潮冲击") == -1:
		_failures.append("brief text should include localized strategy name")
	if brief_text.find("被动生效") == -1:
		_failures.append("brief text should include passive cast mode")
	if brief_text.find("追猎魔登场") == -1:
		_failures.append("brief text should include localized event name")
	if brief_text.find("野犬残形") == -1:
		_failures.append("brief text should include localized ally unit name")
	if brief_text.find("strat_") != -1 or brief_text.find("evt_") != -1 or brief_text.find("enemy_") != -1:
		_failures.append("brief text should not expose english ids")

	var detail_lines: Array = formatter.call("build_tick_detail", rows, 8, "all")
	if detail_lines.size() < 8:
		_failures.append("detail lines should include all supported log types")
	else:
		var detail_text := "\n".join(PackedStringArray(detail_lines))
		if detail_text.find("第8帧释放战技：虚无回响（被动生效）") == -1:
			_failures.append("detail lines should describe passive strategy_cast")
		if detail_text.find("第8帧释放战技：寒潮冲击") == -1:
			_failures.append("detail lines should describe strategy_cast")
		if detail_text.find("第8帧收到事件预警：追猎魔登场") == -1:
			_failures.append("detail lines should describe event_warning")
		if detail_text.find("不可响应：未携带对应对策") == -1:
			_failures.append("detail lines should include warning response reason")
		if detail_text.find("第8帧结算事件：追猎魔登场（已响应）") == -1:
			_failures.append("detail lines should describe event_resolve with responded state")
		if detail_text.find("第8帧承受未响应后果：追猎魔登场") == -1:
			_failures.append("detail lines should describe event_unresolved_effect")
		if detail_text.find("第8帧友军倒下：野犬残形") == -1:
			_failures.append("detail lines should describe ally_down")
		if detail_text.find("第8帧英雄倒下：英雄：天使") == -1:
			_failures.append("detail lines should describe hero_down")
		if detail_text.find("第8帧敌方倒下：游荡魔") == -1:
			_failures.append("detail lines should describe enemy_down")
		if detail_text.find("strat_") != -1 or detail_text.find("evt_") != -1 or detail_text.find("enemy_") != -1:
			_failures.append("detail lines should not expose english ids")

	var warning_only: Array = formatter.call("build_tick_detail", rows, 8, "event_warning")
	if warning_only.size() != 1:
		_failures.append("detail filter should keep only matching type")
	elif String(warning_only[0]).find("事件预警") == -1:
		_failures.append("detail filter should keep warning line")

	var empty_detail: Array = formatter.call("build_tick_detail", rows, 99, "all")
	if empty_detail.size() != 1 or String(empty_detail[0]) != "暂无战术明细":
		_failures.append("detail lines should use chinese fallback when empty")

	var rolling_rows := [
		{"tick": 4, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"},
		{"tick": 6, "type": "event_resolve", "event_id": "evt_hunter_fiend_arrival", "responded": false},
		{"tick": 7, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
	]
	var recent_warning_lines: Array = formatter.call("build_recent_detail", rolling_rows, 7, "event_warning", 6)
	if recent_warning_lines.is_empty():
		_failures.append("build_recent_detail should include previous matching logs")
	else:
		var rolling_text := "\n".join(PackedStringArray(recent_warning_lines))
		if rolling_text.find("第4帧") == -1 or rolling_text.find("事件预警") == -1:
			_failures.append("build_recent_detail should keep tick and warning context")
		if rolling_text.find("evt_") != -1:
			_failures.append("build_recent_detail should not expose english ids")


func _verify_observe_detail_toggle() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		return
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 8
	}
	session_state.last_timeline = [
		{"tick": 0, "entities": []},
		{"tick": 8, "entities": []}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 8, "type": "strategy_cast", "strategy_id": "strat_chill_wave"},
			{"tick": 8, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)

	if not screen.has_method("get_detail_log_visible"):
		_failures.append("missing get_detail_log_visible")

	var detail_button := screen.get_node_or_null("EventPanel/DetailToggleButton") as Button
	var detail_list := screen.get_node_or_null("EventPanel/DetailLogList") as ItemList
	if detail_button == null:
		_failures.append("missing DetailToggleButton")
	if detail_list == null:
		_failures.append("missing DetailLogList")
	if not _failures.is_empty():
		screen.queue_free()
		await process_frame
		return

	screen.call("update_hud_for_tick", 8, session_state.last_battle_result.get("log_entries", []))
	if bool(screen.call("get_detail_log_visible")):
		_failures.append("detail log should be collapsed by default")

	detail_button.emit_signal("pressed")
	await process_frame
	if not bool(screen.call("get_detail_log_visible")):
		_failures.append("detail log should expand after toggle")
	if detail_list.item_count < 2:
		_failures.append("detail log should render formatted entries when expanded")
	else:
		var detail_joined := ""
		for index in range(detail_list.item_count):
			detail_joined += detail_list.get_item_text(index) + "\n"
		if detail_joined.find("寒潮冲击") == -1:
			_failures.append("expanded detail log should include localized strategy text")
		if detail_joined.find("追猎魔登场") == -1:
			_failures.append("expanded detail log should include localized event text")

	detail_button.emit_signal("pressed")
	await process_frame
	if bool(screen.call("get_detail_log_visible")):
		_failures.append("detail log should collapse after second toggle")

	screen.queue_free()
	await process_frame


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
