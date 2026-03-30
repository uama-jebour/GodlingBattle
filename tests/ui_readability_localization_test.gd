extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")
const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")
const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_window_size()
	await _check_preparation_screen()
	await _check_observe_screen()
	await _check_result_screen()
	_finish()


func _check_window_size() -> void:
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	if width < 2560:
		_failures.append("viewport width should be at least 2560")
	if height < 1440:
		_failures.append("viewport height should be at least 1440")


func _check_preparation_screen() -> void:
	var prep: Control = PREP_SCENE.instantiate()
	root.add_child(prep)
	await process_frame

	var title := prep.get_node_or_null("Layout/TitleLabel") as Label
	if title == null:
		_failures.append("missing prep title label")
	else:
		var title_size := int(title.get_theme_font_size("font_size"))
		if title_size < 48:
			_failures.append("prep title font should be >= 48")

	var selection_summary := prep.get_node_or_null("Layout/SelectionSummary") as Label
	if selection_summary == null:
		_failures.append("missing prep selection summary")
	else:
		var summary_text := String(selection_summary.text)
		if summary_text.find("hero_angel") != -1 or summary_text.find("strat_") != -1 or summary_text.find("battle_void_") != -1:
			_failures.append("prep summary should not expose english ids")

	var hero_select := prep.get_node_or_null("Layout/HeroSelect") as OptionButton
	if hero_select == null:
		_failures.append("missing hero select")
	else:
		var hero_font_size := int(hero_select.get_theme_font_size("font_size"))
		if hero_font_size < 40:
			_failures.append("hero select font should be >= 40")
		if hero_select.custom_minimum_size.y < 88.0:
			_failures.append("hero select height should be >= 88")
		var hero_popup := hero_select.get_popup()
		if hero_popup == null or int(hero_popup.get_theme_font_size("font_size")) < 36:
			_failures.append("hero popup menu font should be >= 36")

	var battle_select := prep.get_node_or_null("Layout/BattleSelect") as OptionButton
	if battle_select == null:
		_failures.append("missing battle select")
	else:
		var battle_font_size := int(battle_select.get_theme_font_size("font_size"))
		if battle_font_size < 40:
			_failures.append("battle select font should be >= 40")
		if battle_select.custom_minimum_size.y < 88.0:
			_failures.append("battle select height should be >= 88")

	var seed_input := prep.get_node_or_null("Layout/SeedInput") as SpinBox
	if seed_input == null:
		_failures.append("missing seed input")
	else:
		if seed_input.custom_minimum_size.y < 88.0:
			_failures.append("seed input height should be >= 88")
		var seed_line_edit := seed_input.get_line_edit()
		if seed_line_edit == null:
			_failures.append("seed input line edit should exist")
		else:
			if int(seed_line_edit.get_theme_font_size("font_size")) < 38:
				_failures.append("seed value font should be >= 38")
			if seed_line_edit.custom_minimum_size.y < 72.0:
				_failures.append("seed line edit height should be >= 72")

	var strategy_checkbox := prep.get_node_or_null("Layout/StrategyList/Strategy_strat_void_echo") as CheckBox
	if strategy_checkbox == null:
		_failures.append("missing strategy checkbox")
	else:
		if int(strategy_checkbox.get_theme_font_size("font_size")) < 36:
			_failures.append("strategy checkbox font should be >= 36")
		if strategy_checkbox.custom_minimum_size.y < 72.0:
			_failures.append("strategy checkbox height should be >= 72")
		var checked_icon := strategy_checkbox.get_theme_icon("checked")
		if checked_icon == null or checked_icon.get_width() < 30:
			_failures.append("strategy checkbox checked icon should be >= 30px")

	var start_button := prep.get_node_or_null("Layout/StartBattleButton") as Button
	if start_button == null:
		_failures.append("missing start battle button")
	else:
		var btn_size := int(start_button.get_theme_font_size("font_size"))
		if btn_size < 34:
			_failures.append("start battle button font should be >= 34")

	prep.queue_free()
	await process_frame


func _check_observe_screen() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		return
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1
	}
	session_state.last_timeline = [{"tick": 0, "entities": []}]
	session_state.last_battle_result = {
		"log_entries": [{"tick": 0, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"}]
	}

	var observe: Control = OBSERVE_SCENE.instantiate()
	root.add_child(observe)
	await process_frame

	observe.call("update_hud_for_tick", 0, session_state.last_battle_result.get("log_entries", []))
	var tick_text := String(observe.call("get_tick_text"))
	if tick_text.find("第0帧") == -1:
		_failures.append("observe tick text should be localized")
	if tick_text.find("Tick") != -1:
		_failures.append("observe tick text should not include Tick")

	var event_text := String(observe.call("get_event_text"))
	if event_text.find("事件预警") == -1:
		_failures.append("observe event text should include localized event type")
	if event_text.find("event_warning") != -1:
		_failures.append("observe event text should not expose english event type")

	observe.queue_free()
	await process_frame


func _check_result_screen() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		return
	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	}
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": []
	}

	var result: Control = RESULT_SCENE.instantiate()
	root.add_child(result)
	await process_frame

	var setup_snapshot := result.get_node_or_null("Layout/SetupSnapshotLabel") as Label
	if setup_snapshot == null:
		_failures.append("missing setup snapshot label")
	else:
		var snapshot_text := String(setup_snapshot.text)
		if snapshot_text.find("英雄：") == -1 or snapshot_text.find("友军：") == -1 or snapshot_text.find("战技：") == -1 or snapshot_text.find("关卡：") == -1:
			_failures.append("result snapshot should use chinese field labels")
		if snapshot_text.find("hero_id") != -1 or snapshot_text.find("battle_id") != -1:
			_failures.append("result snapshot should not expose english keys")

	result.queue_free()
	await process_frame


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
