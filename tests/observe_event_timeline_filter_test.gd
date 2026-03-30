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
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []}
	]
	session_state.last_battle_result = {
		"log_entries": [
			{"tick": 0, "type": "event_warning", "event_id": "evt_a"},
			{"tick": 1, "type": "event_resolve", "event_id": "evt_a"},
			{"tick": 1, "type": "strategy_cast", "strategy_id": "strat_chill_wave"}
		]
	}

	var screen: Control = OBSERVE_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var filter_select := screen.get_node_or_null("EventPanel/EventFilterSelect") as OptionButton
	var timeline_label := screen.get_node_or_null("EventPanel/EventTimelineLabel") as Label
	var detail_button := screen.get_node_or_null("EventPanel/DetailToggleButton") as Button
	var detail_list := screen.get_node_or_null("EventPanel/DetailLogList") as ItemList
	if filter_select == null:
		_failures.append("missing EventFilterSelect")
	if timeline_label == null:
		_failures.append("missing EventTimelineLabel")
	if detail_button == null:
		_failures.append("missing DetailToggleButton")
	if detail_list == null:
		_failures.append("missing DetailLogList")
	if not _failures.is_empty():
		screen.queue_free()
		await process_frame
		_finish()
		return

	var all_text := String(timeline_label.text)
	if all_text.find("事件预警") == -1:
		_failures.append("all filter should include 事件预警")
	if all_text.find("事件结算") == -1:
		_failures.append("all filter should include 事件结算")
	if all_text.find("战技施放") == -1:
		_failures.append("all filter should include 战技施放")
	screen.update_hud_for_tick(1, session_state.last_battle_result.get("log_entries", []))
	var summary_all := String(screen.get_tick_summary_text())
	if summary_all.find("事件结算") == -1:
		_failures.append("all filter should include resolve summary at current tick")
	if summary_all.find("寒潮冲击") == -1:
		_failures.append("all filter should include strategy summary at current tick")

	detail_button.emit_signal("pressed")
	await process_frame
	var all_detail_text := ""
	for index in range(detail_list.item_count):
		all_detail_text += detail_list.get_item_text(index) + "\n"
	if all_detail_text.find("结算事件") == -1:
		_failures.append("all filter detail should include resolve line")
	if all_detail_text.find("释放战技") == -1:
		_failures.append("all filter detail should include strategy line")

	filter_select.select(1)
	filter_select.emit_signal("item_selected", 1)
	await process_frame
	var warning_text := String(timeline_label.text)
	if warning_text.find("事件预警") == -1:
		_failures.append("warning filter should include 事件预警")
	if warning_text.find("事件结算") != -1:
		_failures.append("warning filter should exclude 事件结算")
	if warning_text.find("战技施放") != -1:
		_failures.append("warning filter should exclude 战技施放")

	screen.update_hud_for_tick(1, session_state.last_battle_result.get("log_entries", []))
	var warning_summary := String(screen.get_tick_summary_text())
	if warning_summary != "本帧动态：暂无关键事件":
		_failures.append("warning filter should empty brief summary when current tick has no warnings")
	if String(screen.get_event_text()) != "":
		_failures.append("warning filter should hide tick=1 non-warning events")
	if detail_list.item_count != 1 or detail_list.get_item_text(0) != "暂无战术明细":
		_failures.append("warning filter detail should show chinese empty fallback")

	filter_select.select(3)
	filter_select.emit_signal("item_selected", 3)
	await process_frame
	screen.update_hud_for_tick(1, session_state.last_battle_result.get("log_entries", []))
	var strategy_summary := String(screen.get_tick_summary_text())
	if strategy_summary.find("寒潮冲击") == -1:
		_failures.append("strategy filter should keep localized strategy brief")
	if strategy_summary.find("事件结算") != -1:
		_failures.append("strategy filter should exclude resolve summary")
	var strategy_detail := ""
	for index in range(detail_list.item_count):
		strategy_detail += detail_list.get_item_text(index) + "\n"
	if strategy_detail.find("寒潮冲击") == -1:
		_failures.append("strategy filter detail should keep localized strategy line")
	if strategy_detail.find("结算事件") != -1:
		_failures.append("strategy filter detail should exclude resolve line")
	if strategy_detail.find("strat_") != -1:
		_failures.append("strategy filter detail should not expose english ids")

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
