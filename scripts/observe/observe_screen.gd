extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const TOKEN_VIEW_SCENE := preload("res://scenes/observe/token_view.tscn")
const BATTLE_MAP_SCENE := preload("res://scenes/observe/battle_map_view.tscn")
const STRATEGY_CARD_SCENE := preload("res://scenes/observe/strategy_card_view.tscn")
const COMBAT_LINE_OVERLAY := preload("res://scripts/observe/combat_line_overlay.gd")
const BATTLEFIELD_LAYOUT_SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")
const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")
const BATTLE_REPORT_FORMATTER := preload("res://scripts/observe/battle_report_formatter.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")
const FRAME_STEP_SECONDS := 0.05
const JUMP_FRAME_DELTA := 10
const DEATH_MARKER_LINGER_TICKS := 12
const DEFAULT_TICK_RATE := 10.0
const ATTACK_LINE_LINGER_FRAMES := 6
const STRATEGY_LINE_LINGER_FRAMES := 10
const STRATEGY_HIGHLIGHT_LINGER_TICKS := 8
const EVENT_RESPONSE_INDICATOR_LINGER_TICKS := 14
const STRATEGY_NAME_POPUP_LINGER_TICKS := 7
const STRATEGY_NAME_POPUP_SCALE_BOOST := 0.22
const STRATEGY_FLASH_LINGER_TICKS := 3
const STRATEGY_FLASH_MAX_ALPHA := 0.17
const FONT_SIZE_PANEL_TITLE := 22
const FONT_SIZE_PANEL_BODY := 20
const FONT_SIZE_HUD_TICK := 38
const FONT_SIZE_HUD_EVENT := 28
const FONT_SIZE_STRATEGY_POPUP := 46
const HUD_BG_TOP := 10.0
const HUD_BG_HEIGHT := 48.0
const LOG_BAR_COLOR_KEY := "#E7C96A"
const LOG_BAR_COLOR_WARNING := "#E59A55"
const LOG_BAR_COLOR_CAST := "#78C8FF"
const LOG_BAR_COLOR_DOWN := "#F07F7F"
const LOG_BAR_COLOR_DEFAULT := "#B5C0CD"
const RUNTIME_ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)

var _timeline: Array = []
var _frame_index := 0
var _current_frame_index := -1
var _current_tick := 0
var _current_entities: Array = []
var _playback_accumulator := 0.0
var _is_playing := false
var _is_paused := false
var _playback_speed := 0.5
var _token_host: Control
var _ally_layer: Control
var _enemy_layer: Control
var _hud_root: Control
var _screen_flash_rect: ColorRect
var _tick_label: Label
var _event_label: Label
var _strategy_cast_label: Label
var _strategy_name_popup_label: Label
var _token_views: Dictionary = {}
var _event_rows: Array = []
var _battle_result: Dictionary = {}
var _battle_map: Control
var _line_overlay: Control
var _combat_lines: Array = []
var _battlefield_layout_solver := BATTLEFIELD_LAYOUT_SOLVER.new()
var _display_name_resolver := DISPLAY_NAME_RESOLVER.new()
var _battle_report_formatter := BATTLE_REPORT_FORMATTER.new()
var _strategy_panel_strategy_ids: Array[String] = []
var _strategy_panel_cooldown_seconds_by_id: Dictionary = {}
var _strategy_panel_display_name_by_id: Dictionary = {}
var _strategy_cast_ticks_by_id: Dictionary = {}
var _strategy_panel_effect_type_by_id: Dictionary = {}
var _strategy_card_host: HBoxContainer
var _strategy_card_views: Dictionary = {}
var _ally_roster_label: Label
var _enemy_roster_label: Label
var _battle_log_scroll: ScrollContainer
var _battle_log_text_label: RichTextLabel
var _battle_log_legend_label: RichTextLabel
var _prev_hp_by_entity: Dictionary = {}
var _death_marker_until_tick: Dictionary = {}
@onready var _pause_button: Button = $PlaybackPanel/PauseButton
@onready var _step_back_button: Button = $PlaybackPanel/StepBackButton
@onready var _progress_slider: HSlider = $PlaybackPanel/ProgressSlider
@onready var _step_forward_button: Button = $PlaybackPanel/StepForwardButton
@onready var _speed_select: OptionButton = $PlaybackPanel/SpeedSelect
@onready var _event_filter_select: OptionButton = $EventPanel/EventFilterSelect
@onready var _event_timeline_zoom_select: OptionButton = $EventPanel/EventTimelineZoomSelect
@onready var _event_timeline_density_select: OptionButton = $EventPanel/EventTimelineDensitySelect
@onready var _battle_overview_label: Label = $EventPanel/BattleOverviewLabel
@onready var _tick_summary_label: Label = $EventPanel/TickSummaryLabel
@onready var _detail_toggle_button: Button = $EventPanel/DetailToggleButton
@onready var _detail_log_list: ItemList = $EventPanel/DetailLogList
@onready var _event_timeline_label: Label = $EventPanel/EventTimelineLabel
@onready var _event_marker_list: ItemList = $EventPanel/EventMarkerList
var _syncing_progress_slider := false
var _event_filter_type := "all"
var _event_timeline_zoom_step := 1
var _event_timeline_density_limit := 64
var _event_marker_ticks: Array[int] = []
var _detail_log_expanded := false

func _ready() -> void:
	_bind_playback_controls()
	_bind_event_filter_controls()
	_bind_battle_report_controls()
	_hide_legacy_event_panel()
	_ensure_strategy_card_host()
	_ensure_alive_roster_panel()
	_ensure_battle_log_panel()
	_ensure_combat_line_overlay()
	_detail_log_expanded = false
	_refresh_detail_log_visibility()
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
		_event_rows = []
		_rebuild_strategy_card_runtime_cache({}, _event_rows)
		_battle_result = {}
		_refresh_event_timeline()
		_refresh_battle_overview()
		_refresh_tick_summary(_current_tick, _event_rows)
		_refresh_detail_log(_current_tick, _event_rows)
		_refresh_progress_slider()
		_refresh_playback_controls()
		_refresh_strategy_cards(_display_tick())
		_refresh_alive_roster_panel()
		_refresh_battle_log_panel()
		_refresh_combat_line_overlay()
		return
	if session_state.last_timeline.is_empty():
		play_battle(session_state.battle_setup)
	_battle_result = session_state.last_battle_result.duplicate(true)
	_event_rows = _battle_result.get("log_entries", []).duplicate(true)
	_rebuild_strategy_card_runtime_cache(session_state.battle_setup, _event_rows)
	_ensure_token_host()
	_ensure_hud()
	_ensure_map()
	_timeline = session_state.last_timeline.duplicate(true)
	_prev_hp_by_entity.clear()
	_death_marker_until_tick.clear()
	_frame_index = 0
	_current_frame_index = -1
	_playback_accumulator = 0.0
	_is_paused = false
	_playback_speed = 0.5
	_select_speed_by_value(_playback_speed)
	_is_playing = not _timeline.is_empty()
	_refresh_event_timeline()
	_refresh_battle_overview()
	_refresh_tick_summary(_current_tick, _event_rows)
	_refresh_detail_log(_current_tick, _event_rows)
	_refresh_progress_slider()
	_refresh_playback_controls()
	_refresh_strategy_cards(_display_tick())
	_refresh_alive_roster_panel()
	_refresh_battle_log_panel()
	_refresh_combat_line_overlay()
	if _is_playing:
		set_process(true)
	else:
		var app_router := _app_router()
		if app_router != null:
			app_router.goto_result()


func _hide_legacy_event_panel() -> void:
	var event_panel := get_node_or_null("EventPanel") as Control
	if event_panel != null:
		event_panel.visible = false
	var event_panel_bg := get_node_or_null("EventPanelBg") as Control
	if event_panel_bg != null:
		event_panel_bg.visible = false


func _process(delta: float) -> void:
	if not _is_playing or _is_paused:
		return
	_playback_accumulator += delta * _playback_speed
	while _playback_accumulator >= FRAME_STEP_SECONDS and _is_playing and not _is_paused:
		_playback_accumulator -= FRAME_STEP_SECONDS
		var finished := advance_playback_step()
		if finished:
			_is_playing = false
			_refresh_playback_controls()
			set_process(false)
			var app_router := _app_router()
			if app_router != null:
				app_router.goto_result()
			return


func _bind_playback_controls() -> void:
	if _speed_select.item_count == 0:
		_speed_select.add_item("0.5倍速", 0)
		_speed_select.set_item_metadata(0, 0.5)
		_speed_select.add_item("1倍速", 1)
		_speed_select.set_item_metadata(1, 1.0)
		_speed_select.add_item("2倍速", 2)
		_speed_select.set_item_metadata(2, 2.0)
	if not _pause_button.pressed.is_connected(_on_pause_pressed):
		_pause_button.pressed.connect(_on_pause_pressed)
	if not _step_back_button.pressed.is_connected(_on_step_back_pressed):
		_step_back_button.pressed.connect(_on_step_back_pressed)
	if not _progress_slider.value_changed.is_connected(_on_progress_slider_changed):
		_progress_slider.value_changed.connect(_on_progress_slider_changed)
	if not _step_forward_button.pressed.is_connected(_on_step_forward_pressed):
		_step_forward_button.pressed.connect(_on_step_forward_pressed)
	if not _speed_select.item_selected.is_connected(_on_speed_selected):
		_speed_select.item_selected.connect(_on_speed_selected)


func _bind_event_filter_controls() -> void:
	if _event_filter_select.item_count == 0:
		_event_filter_select.add_item("事件筛选：全部", 0)
		_event_filter_select.set_item_metadata(0, "all")
		_event_filter_select.add_item("事件筛选：仅预警", 1)
		_event_filter_select.set_item_metadata(1, "event_warning")
		_event_filter_select.add_item("事件筛选：仅结算", 2)
		_event_filter_select.set_item_metadata(2, "event_resolve")
		_event_filter_select.add_item("事件筛选：仅战技", 3)
		_event_filter_select.set_item_metadata(3, "strategy_cast")
		_event_filter_select.select(0)
	if _event_timeline_zoom_select.item_count == 0:
		_event_timeline_zoom_select.add_item("时间轴缩放：1倍", 0)
		_event_timeline_zoom_select.set_item_metadata(0, 1)
		_event_timeline_zoom_select.add_item("时间轴缩放：2倍", 1)
		_event_timeline_zoom_select.set_item_metadata(1, 2)
		_event_timeline_zoom_select.add_item("时间轴缩放：5倍", 2)
		_event_timeline_zoom_select.set_item_metadata(2, 5)
		_event_timeline_zoom_select.select(0)
	if _event_timeline_density_select.item_count == 0:
		_event_timeline_density_select.add_item("标记密度：高", 0)
		_event_timeline_density_select.set_item_metadata(0, 64)
		_event_timeline_density_select.add_item("标记密度：中", 1)
		_event_timeline_density_select.set_item_metadata(1, 16)
		_event_timeline_density_select.add_item("标记密度：低", 2)
		_event_timeline_density_select.set_item_metadata(2, 1)
		_event_timeline_density_select.select(0)
	if not _event_filter_select.item_selected.is_connected(_on_event_filter_selected):
		_event_filter_select.item_selected.connect(_on_event_filter_selected)
	if not _event_timeline_zoom_select.item_selected.is_connected(_on_event_timeline_zoom_selected):
		_event_timeline_zoom_select.item_selected.connect(_on_event_timeline_zoom_selected)
	if not _event_timeline_density_select.item_selected.is_connected(_on_event_timeline_density_selected):
		_event_timeline_density_select.item_selected.connect(_on_event_timeline_density_selected)
	if not _event_marker_list.item_selected.is_connected(_on_event_marker_selected):
		_event_marker_list.item_selected.connect(_on_event_marker_selected)


func _bind_battle_report_controls() -> void:
	if _detail_toggle_button == null:
		return
	if not _detail_toggle_button.pressed.is_connected(_on_detail_toggle_pressed):
		_detail_toggle_button.pressed.connect(_on_detail_toggle_pressed)
	_refresh_detail_log_visibility()


func _refresh_playback_controls() -> void:
	if _pause_button == null:
		return
	var has_timeline := not _timeline.is_empty()
	if _step_back_button != null:
		_step_back_button.disabled = not has_timeline
	if _step_forward_button != null:
		_step_forward_button.disabled = not has_timeline
	if _progress_slider != null:
		_progress_slider.editable = has_timeline
	if _is_playing:
		_pause_button.text = "继续" if _is_paused else "暂停"
		_pause_button.disabled = false
		return
	_pause_button.text = "已结束"
	_pause_button.disabled = true


func _on_pause_pressed() -> void:
	if not _is_playing:
		return
	_is_paused = not _is_paused
	_refresh_playback_controls()


func _on_speed_selected(index: int) -> void:
	if index < 0 or index >= _speed_select.item_count:
		return
	_playback_speed = float(_speed_select.get_item_metadata(index))


func _on_event_filter_selected(index: int) -> void:
	if index < 0 or index >= _event_filter_select.item_count:
		return
	_event_filter_type = String(_event_filter_select.get_item_metadata(index))
	_refresh_event_timeline()
	update_hud_for_tick(_current_tick, _event_rows)


func _on_event_timeline_zoom_selected(index: int) -> void:
	if index < 0 or index >= _event_timeline_zoom_select.item_count:
		return
	_event_timeline_zoom_step = maxi(1, int(_event_timeline_zoom_select.get_item_metadata(index)))
	_refresh_event_timeline()


func _on_event_timeline_density_selected(index: int) -> void:
	if index < 0 or index >= _event_timeline_density_select.item_count:
		return
	_event_timeline_density_limit = maxi(1, int(_event_timeline_density_select.get_item_metadata(index)))
	_refresh_event_timeline()


func _on_event_marker_selected(index: int) -> void:
	if index < 0 or index >= _event_marker_ticks.size():
		return
	_seek_to_tick(_event_marker_ticks[index])


func _on_detail_toggle_pressed() -> void:
	_detail_log_expanded = not _detail_log_expanded
	_refresh_detail_log(_current_tick, _event_rows)


func _on_step_back_pressed() -> void:
	_jump_frames(-JUMP_FRAME_DELTA)


func _on_step_forward_pressed() -> void:
	_jump_frames(JUMP_FRAME_DELTA)


func _on_progress_slider_changed(value: float) -> void:
	if _syncing_progress_slider or _timeline.is_empty():
		return
	_seek_to_frame(clampi(int(round(value)), 0, _timeline.size() - 1))


func _select_speed_by_value(value: float) -> void:
	for index in range(_speed_select.item_count):
		if is_equal_approx(float(_speed_select.get_item_metadata(index)), value):
			_speed_select.select(index)
			return
	if _speed_select.item_count > 0:
		_speed_select.select(0)


func play_battle(setup: Dictionary) -> void:
	var payload: Dictionary = RUNNER.new().run(setup)
	var session_state := _session_state()
	if session_state == null:
		return
	session_state.last_timeline = payload.get("timeline", []).duplicate(true)
	session_state.last_battle_result = payload.get("result", {}).duplicate(true)


func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = frame.get("entities", []).duplicate(true)
	_prev_hp_by_entity = _hp_lookup_for_frame_index(_current_frame_index - 1)
	_ensure_map()
	var snapshot := build_token_snapshot()
	sync_token_views(snapshot)
	_battle_map.call("set_snapshot", snapshot)
	update_hud_for_tick(_current_tick, _event_rows)


func build_token_snapshot() -> Array:
	var battlefield_bounds := _battlefield_bounds()
	var rows: Array = []
	for entity in _current_entities:
		if not _should_render_entity(entity):
			continue
		rows.append({
			"entity_id": str(entity.get("entity_id", "")),
			"unit_id": str(entity.get("unit_id", "")),
			"display_name": str(entity.get("display_name", "")),
			"side": str(entity.get("side", "")),
			"hp_ratio": _hp_ratio(entity),
			"position": _entity_position_in_battlefield(entity, battlefield_bounds),
			"visual_flags": _build_visual_flags(entity)
		})
	return _battlefield_layout_solver.resolve(rows, battlefield_bounds)


func _should_render_entity(entity: Dictionary) -> bool:
	var entity_id := str(entity.get("entity_id", ""))
	if entity_id.is_empty():
		return false
	if bool(entity.get("alive", false)):
		_death_marker_until_tick.erase(entity_id)
		return true
	var expiry_tick := _death_marker_expiry_tick(entity_id, true)
	return expiry_tick >= 0 and _current_tick <= expiry_tick


func advance_playback_step() -> bool:
	if _frame_index >= _timeline.size():
		return true
	var frame: Dictionary = _timeline[_frame_index]
	_current_frame_index = _frame_index
	apply_timeline_frame(frame)
	_frame_index += 1
	_refresh_progress_slider()
	return _frame_index >= _timeline.size()


func _jump_frames(delta: int) -> void:
	if _timeline.is_empty():
		return
	var base_index := _current_frame_index
	if base_index < 0:
		base_index = clampi(_frame_index, 0, _timeline.size() - 1)
	var target := clampi(base_index + delta, 0, _timeline.size() - 1)
	_seek_to_frame(target)


func _seek_to_frame(frame_index: int) -> void:
	if _timeline.is_empty():
		return
	var target_index := clampi(frame_index, 0, _timeline.size() - 1)
	var frame: Dictionary = _timeline[target_index]
	_current_frame_index = target_index
	apply_timeline_frame(frame)
	_frame_index = target_index + 1
	_playback_accumulator = 0.0
	_is_playing = _frame_index < _timeline.size()
	set_process(_is_playing)
	_refresh_progress_slider()
	_refresh_playback_controls()


func _refresh_progress_slider() -> void:
	if _progress_slider == null:
		return
	_syncing_progress_slider = true
	if _timeline.is_empty():
		_progress_slider.min_value = 0.0
		_progress_slider.max_value = 0.0
		_progress_slider.step = 1.0
		_progress_slider.value = 0.0
		_syncing_progress_slider = false
		return
	_progress_slider.min_value = 0.0
	_progress_slider.max_value = float(_timeline.size() - 1)
	_progress_slider.step = 1.0
	var current_index := _current_frame_index
	if current_index < 0:
		current_index = clampi(_frame_index, 0, _timeline.size() - 1)
	_progress_slider.value = float(clampi(current_index, 0, _timeline.size() - 1))
	_syncing_progress_slider = false


func sync_token_views(snapshot: Array) -> void:
	_ensure_token_host()
	var alive_ids: Dictionary = {}
	for row in snapshot:
		var entity_id := str(row.get("entity_id", ""))
		if entity_id.is_empty():
			continue
		var token = _token_views.get(entity_id, null)
		var target_layer := _layer_for_side(str(row.get("side", "")))
		if token == null:
			token = TOKEN_VIEW_SCENE.instantiate()
			token.size = token.custom_minimum_size
			target_layer.add_child(token)
			_token_views[entity_id] = token
		elif token.get_parent() != target_layer:
			token.reparent(target_layer)
		token.apply_snapshot(row)
		if token.has_method("set_visual_flags"):
			token.call("set_visual_flags", _visual_flags_from_snapshot(row))
		alive_ids[entity_id] = true
	for entity_id in _token_views.keys():
		if alive_ids.has(entity_id):
			continue
		var stale: Node = _token_views[entity_id]
		stale.queue_free()
		_token_views.erase(entity_id)


func get_token_view_count() -> int:
	return _token_views.size()


func get_token_view(entity_id: String) -> Node:
	return _token_views.get(entity_id, null)


func get_layer_child_count(side: String) -> int:
	_ensure_token_host()
	var layer := _layer_for_side(side)
	return layer.get_child_count()


func get_token_parent_name(entity_id: String) -> String:
	var token: Node = _token_views.get(entity_id, null)
	if token == null:
		return ""
	var parent := token.get_parent()
	if parent == null:
		return ""
	return parent.name


func update_hud_for_tick(tick: int, event_rows: Array) -> void:
	_ensure_hud()
	_current_tick = tick
	_tick_label.text = "第%d帧" % tick
	var messages: Array[String] = []
	var filtered_rows := _filter_event_rows(event_rows)
	for row in filtered_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		messages.append(_build_event_row_text(row))
	if messages.is_empty():
		_event_label.text = ""
	else:
		_event_label.text = " | ".join(messages)
	_strategy_cast_label.text = _build_strategy_cast_text(tick, filtered_rows)
	_refresh_strategy_cast_fx(tick)
	_refresh_tick_summary(tick, event_rows)
	_refresh_detail_log(tick, event_rows)
	_refresh_battle_overview()
	_refresh_strategy_cards(tick)
	_refresh_alive_roster_panel()
	_refresh_battle_log_panel()
	_refresh_combat_line_overlay()


func get_tick_text() -> String:
	_ensure_hud()
	return _tick_label.text


func get_event_text() -> String:
	_ensure_hud()
	return _event_label.text


func get_strategy_cast_text() -> String:
	_ensure_hud()
	return _strategy_cast_label.text


func get_alive_roster_text() -> String:
	var sections := _build_alive_roster_sections()
	return "我方\n%s\n敌方\n%s" % [
		_roster_lines_text(sections.get("ally", [])),
		_roster_lines_text(sections.get("enemy", []))
	]


func get_battle_log_text() -> String:
	return "\n".join(PackedStringArray(_build_battle_log_lines()))


func get_battle_log_legend_text() -> String:
	if _battle_log_legend_label == null:
		return ""
	return _battle_log_legend_label.get_parsed_text()


func get_event_timeline_text() -> String:
	if _event_timeline_label == null:
		return ""
	return _event_timeline_label.text


func get_event_timeline_marker_count() -> int:
	return _event_marker_ticks.size()


func get_battle_overview_text() -> String:
	if _battle_overview_label == null:
		return ""
	return _battle_overview_label.text


func get_tick_summary_text() -> String:
	if _tick_summary_label == null:
		return ""
	return _tick_summary_label.text


func get_detail_log_visible() -> bool:
	return _detail_log_list != null and _detail_log_list.visible


func get_combat_line_count() -> int:
	return _combat_lines.size()


func get_attack_line_count() -> int:
	return _line_count_by_kind("attack")


func get_strategy_line_count() -> int:
	return _line_count_by_kind("strategy")


func get_strategy_card_highlight_count() -> int:
	var count := 0
	for strategy_id in _strategy_card_views.keys():
		var card: Variant = _strategy_card_views.get(strategy_id, null)
		if card == null:
			continue
		var alpha := float(card.get("highlight_alpha"))
		if alpha > 0.001:
			count += 1
	return count


func get_strategy_target_highlight_count() -> int:
	var count := 0
	for entity_id in _token_views.keys():
		var token: Variant = _token_views.get(entity_id, null)
		if token == null:
			continue
		var alpha := float(token.get("strategy_highlight_alpha"))
		if alpha > 0.001:
			count += 1
	return count


func get_strategy_origin_pulse_count() -> int:
	var count := 0
	for row in _combat_lines:
		var line := row as Dictionary
		if str(line.get("kind", "")) != "strategy":
			continue
		if float(line.get("origin_pulse_alpha", 0.0)) > 0.001:
			count += 1
	return count


func get_event_response_indicator_count() -> int:
	return _line_count_by_kind("event_response_indicator")


func get_event_response_seal_count() -> int:
	var count := 0
	for row in _combat_lines:
		var line := row as Dictionary
		if str(line.get("kind", "")) != "event_response_indicator":
			continue
		if str(line.get("variant", "")) != "seal_x":
			continue
		count += 1
	return count


func get_strategy_name_popup_alpha() -> float:
	if _strategy_name_popup_label == null:
		return 0.0
	return _strategy_name_popup_label.modulate.a


func get_strategy_screen_flash_alpha() -> float:
	if _screen_flash_rect == null:
		return 0.0
	return _screen_flash_rect.color.a


func _build_visual_flags(entity: Dictionary) -> Dictionary:
	var entity_id := str(entity.get("entity_id", ""))
	var hp_now := float(entity.get("hp", 0.0))
	var hp_prev := float(_prev_hp_by_entity.get(entity_id, hp_now))
	var is_dead := not bool(entity.get("alive", false))
	var damage_value := maxi(0, roundi(hp_prev - hp_now))
	return {
		"is_hit": hp_now < hp_prev,
		"damage_value": damage_value,
		"is_affected": _has_tick_effect(entity_id, _current_tick),
		"strategy_highlight_alpha": _strategy_target_highlight_alpha(entity_id, _current_tick),
		"is_dead": is_dead,
		"show_death_marker_until_tick": _death_marker_expiry_tick(entity_id, is_dead),
		"current_tick": _current_tick
	}


func _visual_flags_from_snapshot(row: Dictionary) -> Dictionary:
	var flags = row.get("visual_flags", {})
	if flags is Dictionary:
		return flags
	return {
		"is_hit": false,
		"damage_value": 0,
		"is_affected": false,
		"strategy_highlight_alpha": 0.0,
		"is_dead": false,
		"show_death_marker_until_tick": -1,
		"current_tick": _current_tick
	}


func _death_marker_expiry_tick(entity_id: String, is_dead: bool) -> int:
	if not is_dead:
		_death_marker_until_tick.erase(entity_id)
		return -1
	if _death_marker_until_tick.has(entity_id):
		return int(_death_marker_until_tick[entity_id])
	var death_tick := _first_death_tick_for_entity(entity_id)
	var expiry_tick := death_tick + DEATH_MARKER_LINGER_TICKS
	_death_marker_until_tick[entity_id] = expiry_tick
	return expiry_tick


func _first_death_tick_for_entity(entity_id: String) -> int:
	if _current_frame_index < 0 or _timeline.is_empty():
		return _current_tick
	var was_alive := true
	for index in range(_current_frame_index + 1):
		var frame: Dictionary = _timeline[index]
		var entity := _entity_in_frame(frame.get("entities", []), entity_id)
		if entity.is_empty():
			continue
		var is_alive := bool(entity.get("alive", false))
		if was_alive and not is_alive:
			return int(frame.get("tick", _current_tick))
		was_alive = is_alive
	return _current_tick


func _entity_in_frame(entities: Array, entity_id: String) -> Dictionary:
	for entity in entities:
		if str(entity.get("entity_id", "")) == entity_id:
			return entity
	return {}


func _hp_lookup_for_frame_index(frame_index: int) -> Dictionary:
	if frame_index < 0 or frame_index >= _timeline.size():
		return {}
	var hp_by_entity: Dictionary = {}
	var frame_entities: Array = (_timeline[frame_index] as Dictionary).get("entities", [])
	for entity in frame_entities:
		hp_by_entity[str(entity.get("entity_id", ""))] = float(entity.get("hp", 0.0))
	return hp_by_entity


func _has_tick_effect(entity_id: String, tick: int) -> bool:
	for row in _event_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if _row_targets_entity(row, entity_id):
			return true
	return false


func _row_targets_entity(row: Dictionary, entity_id: String) -> bool:
	if str(row.get("entity_id", "")) == entity_id:
		return true
	var target_ids = row.get("entity_ids", [])
	if target_ids is Array:
		for candidate in target_ids:
			if str(candidate) == entity_id:
				return true
	return false


func _hp_ratio(entity: Dictionary) -> float:
	var hp := float(entity.get("hp", 0.0))
	var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
	return clampf(hp / max_hp, 0.0, 1.0)


func _entity_position(entity: Dictionary) -> Vector2:
	var raw = entity.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _entity_position_in_battlefield(entity: Dictionary, battlefield_bounds: Rect2) -> Vector2:
	var runtime_position := _entity_position(entity)
	if battlefield_bounds.size.x <= 0.0 or battlefield_bounds.size.y <= 0.0:
		return runtime_position
	var arena := RUNTIME_ARENA_BOUNDS
	if arena.size.x <= 0.0 or arena.size.y <= 0.0:
		return runtime_position
	var ratio_x := clampf((runtime_position.x - arena.position.x) / arena.size.x, 0.0, 1.0)
	var ratio_y := clampf((runtime_position.y - arena.position.y) / arena.size.y, 0.0, 1.0)
	return Vector2(
		battlefield_bounds.position.x + battlefield_bounds.size.x * ratio_x,
		battlefield_bounds.position.y + battlefield_bounds.size.y * ratio_y
	)


func _battlefield_bounds() -> Rect2:
	var host := _battlefield_panel_host()
	var panel_size := host.size
	if _battle_map != null and _battle_map.has_method("get_playable_bounds"):
		var playable: Rect2 = _battle_map.call("get_playable_bounds")
		if playable.size.x > 0.0 and playable.size.y > 0.0:
			var hud_floor := _hud_reserved_bottom() + 8.0
			var y_start := maxf(playable.position.y, hud_floor)
			var y_end := playable.end.y
			if y_end > y_start:
				return Rect2(
					Vector2(playable.position.x, y_start),
					Vector2(playable.size.x, y_end - y_start)
				)
			return playable
	if panel_size.x > 0.0 and panel_size.y > 0.0:
		return Rect2(Vector2.ZERO, panel_size)
	if _battle_map != null:
		var battle_map_rect := _battle_map.get_rect()
		if battle_map_rect.size.x > 0.0 and battle_map_rect.size.y > 0.0:
			return battle_map_rect
	var screen_rect := get_rect()
	if screen_rect.size.x > 0.0 and screen_rect.size.y > 0.0:
		return screen_rect
	return Rect2(0, 0, 640, 360)


func _hud_reserved_bottom() -> float:
	if _hud_root == null:
		return 0.0
	var hud_bg := _hud_root.get_node_or_null("HudBg") as Control
	if hud_bg != null and hud_bg.visible:
		return hud_bg.position.y + hud_bg.size.y
	return 0.0


func _ensure_token_host() -> void:
	var battlefield_panel := _battlefield_panel_host()
	if _token_host != null:
		if _token_host.get_parent() != battlefield_panel:
			_token_host.reparent(battlefield_panel)
		_token_host.set_anchors_preset(Control.PRESET_FULL_RECT)
		return
	_token_host = Control.new()
	_token_host.name = "TokenHost"
	_token_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield_panel.add_child(_token_host)

	_ally_layer = Control.new()
	_ally_layer.name = "AllyLayer"
	_ally_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ally_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_token_host.add_child(_ally_layer)

	_enemy_layer = Control.new()
	_enemy_layer.name = "EnemyLayer"
	_enemy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_enemy_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_token_host.add_child(_enemy_layer)


func _ensure_hud() -> void:
	var battlefield_panel := _battlefield_panel_host()
	if _hud_root != null:
		if _hud_root.get_parent() != battlefield_panel:
			_hud_root.reparent(battlefield_panel)
		_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		return
	_hud_root = Control.new()
	_hud_root.name = "HudRoot"
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield_panel.add_child(_hud_root)

	_screen_flash_rect = ColorRect.new()
	_screen_flash_rect.name = "StrategyScreenFlash"
	_screen_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_flash_rect.color = Color(0.78, 0.90, 1.0, 0.0)
	_hud_root.add_child(_screen_flash_rect)

	var hud_bg := ColorRect.new()
	hud_bg.name = "HudBg"
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bg.position = Vector2(14, HUD_BG_TOP)
	hud_bg.size = Vector2(1400, HUD_BG_HEIGHT)
	hud_bg.color = Color(0.05, 0.08, 0.11, 0.78)
	_hud_root.add_child(hud_bg)

	_tick_label = Label.new()
	_tick_label.name = "TickLabel"
	_tick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tick_label.position = Vector2(20, HUD_BG_TOP + 2.0)
	_tick_label.custom_minimum_size = Vector2(180, HUD_BG_HEIGHT - 4.0)
	_tick_label.text = "第0帧"
	_tick_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_TICK)
	_hud_root.add_child(_tick_label)

	_event_label = Label.new()
	_event_label.name = "EventLabel"
	_event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_label.position = Vector2(220, HUD_BG_TOP + 8.0)
	_event_label.custom_minimum_size = Vector2(700, HUD_BG_HEIGHT - 8.0)
	_event_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_event_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_EVENT)
	_event_label.text = ""
	_hud_root.add_child(_event_label)

	_strategy_cast_label = Label.new()
	_strategy_cast_label.name = "StrategyCastLabel"
	_strategy_cast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strategy_cast_label.position = Vector2(940, HUD_BG_TOP + 8.0)
	_strategy_cast_label.custom_minimum_size = Vector2(460, HUD_BG_HEIGHT - 8.0)
	_strategy_cast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_strategy_cast_label.add_theme_font_size_override("font_size", FONT_SIZE_HUD_EVENT)
	_strategy_cast_label.text = ""
	_hud_root.add_child(_strategy_cast_label)

	_strategy_name_popup_label = Label.new()
	_strategy_name_popup_label.name = "StrategyNamePopupLabel"
	_strategy_name_popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strategy_name_popup_label.position = Vector2(540, HUD_BG_TOP + HUD_BG_HEIGHT + 12.0)
	_strategy_name_popup_label.custom_minimum_size = Vector2(460, 64)
	_strategy_name_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_strategy_name_popup_label.add_theme_font_size_override("font_size", FONT_SIZE_STRATEGY_POPUP)
	_strategy_name_popup_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0, 1.0))
	_strategy_name_popup_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	_strategy_name_popup_label.add_theme_constant_override("shadow_offset_x", 1)
	_strategy_name_popup_label.add_theme_constant_override("shadow_offset_y", 2)
	_strategy_name_popup_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_strategy_name_popup_label.text = ""
	_hud_root.add_child(_strategy_name_popup_label)


func _ensure_map() -> void:
	var battlefield_panel := _battlefield_panel_host()
	if _battle_map != null:
		if _battle_map.get_parent() != battlefield_panel:
			_battle_map.reparent(battlefield_panel)
		_battle_map.set_anchors_preset(Control.PRESET_FULL_RECT)
		battlefield_panel.move_child(_battle_map, 0)
		return
	_battle_map = BATTLE_MAP_SCENE.instantiate()
	_battle_map.name = "BattleMap"
	_battle_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	battlefield_panel.add_child(_battle_map)
	battlefield_panel.move_child(_battle_map, 0)


func _ensure_combat_line_overlay() -> void:
	if _line_overlay != null:
		if _line_overlay.get_parent() != self:
			_line_overlay.reparent(self)
		_line_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		return
	_line_overlay = COMBAT_LINE_OVERLAY.new()
	_line_overlay.name = "CombatLineOverlay"
	_line_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_overlay.z_index = 40
	_line_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_line_overlay)


func _refresh_combat_line_overlay() -> void:
	_ensure_combat_line_overlay()
	_combat_lines = _build_combat_lines(_display_tick())
	if _line_overlay != null and _line_overlay.has_method("set_lines"):
		_line_overlay.call("set_lines", _combat_lines)


func _refresh_strategy_cast_fx(tick: int) -> void:
	_refresh_strategy_name_popup(tick)
	_refresh_strategy_screen_flash(tick)


func _refresh_strategy_name_popup(tick: int) -> void:
	if _strategy_name_popup_label == null:
		return
	var popup := _strategy_popup_state_for_tick(tick)
	var alpha := float(popup.get("alpha", 0.0))
	if alpha <= 0.001:
		_strategy_name_popup_label.text = ""
		_strategy_name_popup_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_strategy_name_popup_label.scale = Vector2.ONE
		return
	_strategy_name_popup_label.text = String(popup.get("text", ""))
	var scale_factor := float(popup.get("scale", 1.0))
	_strategy_name_popup_label.scale = Vector2(scale_factor, scale_factor)
	_strategy_name_popup_label.pivot_offset = _strategy_name_popup_label.size * 0.5
	_strategy_name_popup_label.modulate = Color(1.0, 1.0, 1.0, alpha)


func _refresh_strategy_screen_flash(tick: int) -> void:
	if _screen_flash_rect == null:
		return
	var alpha := _strategy_screen_flash_alpha(tick)
	_screen_flash_rect.color = Color(0.78, 0.90, 1.0, alpha)


func _build_combat_lines(tick: int) -> Array:
	var lines: Array = []
	lines.append_array(_build_attack_lines_with_linger())
	lines.append_array(_build_strategy_lines_with_linger(tick))
	lines.append_array(_build_event_response_indicator_lines_with_linger(tick))
	return lines


func _build_event_response_indicator_lines_with_linger(tick: int) -> Array:
	if _event_rows.is_empty():
		return []
	var lines: Array = []
	for age in range(EVENT_RESPONSE_INDICATOR_LINGER_TICKS):
		var target_tick := tick - age
		var alpha := 1.0 - (float(age) / float(EVENT_RESPONSE_INDICATOR_LINGER_TICKS))
		var life_t := float(age) / float(maxi(1, EVENT_RESPONSE_INDICATOR_LINGER_TICKS - 1))
		lines.append_array(_build_event_response_indicator_lines_for_tick(target_tick, alpha, life_t))
	return lines


func _build_event_response_indicator_lines_for_tick(target_tick: int, alpha: float, life_t: float) -> Array:
	var rows: Array = []
	for row in _event_rows:
		if int(row.get("tick", -1)) != target_tick:
			continue
		if str(row.get("type", "")) != "event_resolve":
			continue
		if not bool(row.get("responded", false)):
			continue
		var anchor := _event_response_indicator_anchor_in_overlay()
		if anchor == Vector2.ZERO:
			continue
		var half := 46.0 + alpha * 32.0
		var from := anchor + Vector2(-half, 0.0)
		var to := anchor + Vector2(half, 0.0)
		var color := Color(0.40, 1.0, 0.86, 0.96)
		color.a *= 0.48 + alpha * 0.52
		rows.append({
			"kind": "event_response_indicator",
			"variant": "seal_x",
			"from": from,
			"to": to,
			"color": color,
			"width": 2.6 + alpha * 3.4,
			"phase": float((target_tick + 5) % 9) * 0.11,
			"pulse_speed": 1.2 + alpha * 1.5,
			"life_t": life_t
		})
	return rows


func _event_response_indicator_anchor_in_overlay() -> Vector2:
	var enemy_centers: Array[Vector2] = []
	for entity in _current_entities:
		if not bool(entity.get("alive", false)):
			continue
		if str(entity.get("side", "")) != "enemy":
			continue
		var center := _token_center_in_overlay(str(entity.get("entity_id", "")))
		if center == Vector2.ZERO:
			continue
		enemy_centers.append(center)
	if not enemy_centers.is_empty():
		var sum := Vector2.ZERO
		for center in enemy_centers:
			sum += center
		return sum / float(enemy_centers.size())
	var battlefield_panel := _battlefield_panel_host()
	if battlefield_panel == null:
		return Vector2.ZERO
	var rect := battlefield_panel.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return Vector2.ZERO
	var global_anchor := rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.42)
	return _overlay_point_from_global(global_anchor)


func _build_attack_lines_with_linger() -> Array:
	if _current_frame_index <= 0:
		return []
	var lines: Array = []
	for age in range(ATTACK_LINE_LINGER_FRAMES):
		var frame_index := _current_frame_index - age
		if frame_index <= 0:
			break
		var alpha := 1.0 - (float(age) / float(ATTACK_LINE_LINGER_FRAMES))
		var life_t := float(age) / float(maxi(1, ATTACK_LINE_LINGER_FRAMES - 1))
		lines.append_array(_build_attack_lines_for_frame(frame_index, alpha, life_t))
	return lines


func _build_attack_lines_for_frame(frame_index: int, alpha: float, life_t: float) -> Array:
	var prev_lookup := _entities_lookup_for_frame_index(frame_index - 1)
	if prev_lookup.is_empty():
		return []
	var frame_lookup := _entities_lookup_for_frame_index(frame_index)
	var lines_from_attacker := _build_attack_lines_from_attacker_transitions(prev_lookup, frame_lookup, frame_index, alpha, life_t)
	if not lines_from_attacker.is_empty():
		return lines_from_attacker
	var lines: Array = []
	for entity_id in prev_lookup.keys():
		var previous := prev_lookup[entity_id] as Dictionary
		var current := frame_lookup.get(entity_id, previous) as Dictionary
		var hp_prev := float(previous.get("hp", 0.0))
		var hp_now := float(current.get("hp", hp_prev))
		if hp_now >= hp_prev - 0.01:
			continue
		var attacker_id := _infer_attacker_for_target(previous, prev_lookup)
		if attacker_id.is_empty():
			continue
		var from := _token_center_in_overlay(attacker_id)
		var to := _token_center_in_overlay(str(entity_id))
		if from == Vector2.ZERO or to == Vector2.ZERO:
			continue
		var color := _attack_line_color(str((prev_lookup[attacker_id] as Dictionary).get("side", "")))
		color.a *= 0.35 + alpha * 0.65
		lines.append({
			"kind": "attack",
			"from": from,
			"to": to,
			"color": color,
			"width": 1.8 + alpha * 2.2,
			"phase": float(frame_index % 11) * 0.07,
			"pulse_speed": 1.0 + alpha * 1.2,
			"life_t": life_t
		})
	return lines


func _build_attack_lines_from_attacker_transitions(prev_lookup: Dictionary, frame_lookup: Dictionary, frame_index: int, alpha: float, life_t: float) -> Array:
	var lines: Array = []
	for entity_id in prev_lookup.keys():
		var previous := prev_lookup[entity_id] as Dictionary
		var current := frame_lookup.get(entity_id, previous) as Dictionary
		if not _did_attack_this_frame(previous, current):
			continue
		if not bool(previous.get("alive", false)):
			continue
		var attacker_side := str(previous.get("side", ""))
		if attacker_side.is_empty():
			continue
		var target_id := _nearest_opponent_entity_id(previous, prev_lookup)
		if target_id.is_empty():
			continue
		var from := _token_center_in_overlay(str(entity_id))
		var to := _token_center_in_overlay(target_id)
		if from == Vector2.ZERO or to == Vector2.ZERO:
			continue
		var color := _attack_line_color(attacker_side)
		color.a *= 0.35 + alpha * 0.65
		lines.append({
			"kind": "attack",
			"from": from,
			"to": to,
			"color": color,
			"width": 1.8 + alpha * 2.2,
			"phase": float((frame_index + str(entity_id).length()) % 11) * 0.07,
			"pulse_speed": 1.0 + alpha * 1.2,
			"life_t": life_t
		})
	return lines


func _did_attack_this_frame(previous: Dictionary, current: Dictionary) -> bool:
	if not previous.has("attack_cooldown_ticks") or not current.has("attack_cooldown_ticks"):
		return false
	var previous_cooldown := int(previous.get("attack_cooldown_ticks", -1))
	var current_cooldown := int(current.get("attack_cooldown_ticks", -1))
	return previous_cooldown <= 0 and current_cooldown > 0


func _nearest_opponent_entity_id(attacker: Dictionary, lookup: Dictionary) -> String:
	var attacker_side := str(attacker.get("side", ""))
	var attacker_pos := _entity_position(attacker)
	var best_id := ""
	var best_distance := INF
	for entity_id in lookup.keys():
		var target := lookup[entity_id] as Dictionary
		if not bool(target.get("alive", false)):
			continue
		if _is_same_team_side(attacker_side, str(target.get("side", ""))):
			continue
		var distance := attacker_pos.distance_to(_entity_position(target))
		if distance >= best_distance:
			continue
		best_distance = distance
		best_id = str(entity_id)
	return best_id


func _build_strategy_lines_with_linger(tick: int) -> Array:
	if _event_rows.is_empty():
		return []
	var lines: Array = []
	for age in range(STRATEGY_LINE_LINGER_FRAMES):
		var target_tick := tick - age
		var alpha := 1.0 - (float(age) / float(STRATEGY_LINE_LINGER_FRAMES))
		var life_t := float(age) / float(maxi(1, STRATEGY_LINE_LINGER_FRAMES - 1))
		lines.append_array(_build_strategy_lines_for_tick(target_tick, alpha, life_t))
	return lines


func _build_strategy_lines_for_tick(tick: int, alpha: float, life_t: float) -> Array:
	if _event_rows.is_empty():
		return []
	var lines: Array = []
	for row in _event_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var strategy_id := str(row.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		var origin := _strategy_card_center_in_overlay(strategy_id)
		if origin == Vector2.ZERO:
			continue
		for target_id in _strategy_target_entity_ids(strategy_id):
			var target := _token_center_in_overlay(target_id)
			if target == Vector2.ZERO:
				continue
			var color := Color(0.45, 0.82, 1.0, 0.92)
			color.a *= 0.30 + alpha * 0.70
			var strategy_highlight_alpha := _strategy_highlight_alpha_for_tick(tick)
			lines.append({
				"kind": "strategy",
				"from": origin,
				"to": target,
				"color": color,
				"width": 2.2 + alpha * 2.8,
				"phase": float((tick + target_id.length()) % 9) * 0.09,
				"pulse_speed": 1.3 + alpha * 1.4,
				"life_t": life_t,
				"origin_pulse_alpha": strategy_highlight_alpha
			})
	return lines


func _attack_line_color(side: String) -> Color:
	if side == "enemy":
		return Color(0.93, 0.38, 0.38, 0.86)
	return Color(0.45, 0.78, 1.0, 0.86)


func _strategy_target_entity_ids(strategy_id: String) -> Array[String]:
	var targets: Array[String] = []
	var effect_type := str(_strategy_panel_effect_type_by_id.get(strategy_id, ""))
	if effect_type == "enemy_group_slow":
		return _alive_entity_ids(true)
	if effect_type == "enemy_front_nuke":
		var front_enemy := _front_alive_enemy_entity_id()
		if not front_enemy.is_empty():
			targets.append(front_enemy)
		return targets
	if effect_type == "ally_tag_attack_shift":
		return _alive_entity_ids(false)
	return _alive_entity_ids(true)


func _front_alive_enemy_entity_id() -> String:
	var best_id := ""
	var best_x := INF
	for entity in _current_entities:
		if not bool(entity.get("alive", false)):
			continue
		if str(entity.get("side", "")) != "enemy":
			continue
		var pos := _entity_position(entity)
		if pos.x >= best_x:
			continue
		best_x = pos.x
		best_id = str(entity.get("entity_id", ""))
	return best_id


func _alive_entity_ids(enemy_only: bool) -> Array[String]:
	var ids: Array[String] = []
	for entity in _current_entities:
		if not bool(entity.get("alive", false)):
			continue
		var side := str(entity.get("side", ""))
		if enemy_only and side != "enemy":
			continue
		if not enemy_only and side == "enemy":
			continue
		var entity_id := str(entity.get("entity_id", ""))
		if not entity_id.is_empty():
			ids.append(entity_id)
	return ids


func _strategy_card_center_in_overlay(strategy_id: String) -> Vector2:
	if _line_overlay == null:
		return Vector2.ZERO
	var card := _strategy_card_views.get(strategy_id, null) as Control
	if card != null:
		var rect := card.get_global_rect()
		if rect.size.x > 1.0 and rect.size.y > 1.0:
			return _overlay_point_from_global(rect.position + rect.size * 0.5)
	var strategy_panel := get_node_or_null("LayoutRoot/LeftColumn/StrategyPanel") as Control
	if strategy_panel == null:
		return Vector2.ZERO
	var fallback_rect := strategy_panel.get_global_rect()
	if fallback_rect.size.x <= 1.0 or fallback_rect.size.y <= 1.0:
		return Vector2.ZERO
	return _overlay_point_from_global(fallback_rect.position + fallback_rect.size * 0.5)


func _token_center_in_overlay(entity_id: String) -> Vector2:
	if _line_overlay == null:
		return Vector2.ZERO
	var token := _token_views.get(entity_id, null) as Control
	if token == null:
		return Vector2.ZERO
	var rect := token.get_global_rect()
	return _overlay_point_from_global(rect.position + rect.size * 0.5)


func _overlay_point_from_global(global_point: Vector2) -> Vector2:
	if _line_overlay == null:
		return Vector2.ZERO
	return _line_overlay.get_global_transform_with_canvas().affine_inverse() * global_point


func _entities_lookup_for_frame_index(frame_index: int) -> Dictionary:
	if frame_index < 0 or frame_index >= _timeline.size():
		return {}
	var frame := _timeline[frame_index] as Dictionary
	return _entity_lookup(frame.get("entities", []))


func _entity_lookup(entities: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for entity in entities:
		var entity_id := str(entity.get("entity_id", ""))
		if entity_id.is_empty():
			continue
		lookup[entity_id] = entity
	return lookup


func _infer_attacker_for_target(target: Dictionary, prev_lookup: Dictionary) -> String:
	var target_side := str(target.get("side", ""))
	var target_pos := _entity_position(target)
	var strict_id := _nearest_opponent_for_target(target_side, target_pos, prev_lookup, true)
	if not strict_id.is_empty():
		return strict_id
	return _nearest_opponent_for_target(target_side, target_pos, prev_lookup, false)


func _nearest_opponent_for_target(target_side: String, target_pos: Vector2, prev_lookup: Dictionary, enforce_range: bool) -> String:
	var best_id := ""
	var best_distance := INF
	for entity_id in prev_lookup.keys():
		var candidate := prev_lookup[entity_id] as Dictionary
		if not bool(candidate.get("alive", false)):
			continue
		if _is_same_team_side(target_side, str(candidate.get("side", ""))):
			continue
		var distance := _entity_position(candidate).distance_to(target_pos)
		if enforce_range:
			var attack_range := float(candidate.get("attack_range", 0.0))
			if attack_range > 0.0 and distance > attack_range + 30.0:
				continue
		if distance >= best_distance:
			continue
		best_distance = distance
		best_id = str(entity_id)
	return best_id


func _is_same_team_side(side_a: String, side_b: String) -> bool:
	if side_a == "enemy":
		return side_b == "enemy"
	if side_b == "enemy":
		return false
	return true


func _line_count_by_kind(kind: String) -> int:
	var count := 0
	for row in _combat_lines:
		if str((row as Dictionary).get("kind", "")) == kind:
			count += 1
	return count


func _layer_for_side(side: String) -> Control:
	if side == "enemy":
		return _enemy_layer
	return _ally_layer


func _ensure_strategy_card_host() -> void:
	if _strategy_card_host != null:
		return
	var strategy_panel := get_node_or_null("LayoutRoot/LeftColumn/StrategyPanel") as VBoxContainer
	if strategy_panel == null:
		return
	var hint_label := get_node_or_null("LayoutRoot/LeftColumn/StrategyPanel/StrategyHint") as Label
	if hint_label != null:
		hint_label.visible = false
	_strategy_card_host = HBoxContainer.new()
	_strategy_card_host.name = "StrategyCardHost"
	_strategy_card_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strategy_card_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_strategy_card_host.add_theme_constant_override("separation", 10)
	strategy_panel.add_child(_strategy_card_host)


func _battlefield_panel_host() -> Control:
	var battlefield_runtime := get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldRuntime") as Control
	if battlefield_runtime != null:
		var hint_label := get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel/BattlefieldHint") as Label
		if hint_label != null:
			hint_label.visible = false
		return battlefield_runtime
	var battlefield_panel := get_node_or_null("LayoutRoot/LeftColumn/BattlefieldPanel") as Control
	if battlefield_panel != null:
		return battlefield_panel
	return self


func _ensure_alive_roster_panel() -> void:
	if _ally_roster_label != null and _enemy_roster_label != null:
		return
	var panel := get_node_or_null("LayoutRoot/RightColumn/AliveRosterPanel") as VBoxContainer
	if panel == null:
		return
	var hint_label := get_node_or_null("LayoutRoot/RightColumn/AliveRosterPanel/RosterHint") as Label
	if hint_label != null:
		hint_label.visible = false
	var columns := HBoxContainer.new()
	columns.name = "AliveRosterColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	panel.add_child(columns)
	var ally_column := _build_roster_column("我方")
	var enemy_column := _build_roster_column("敌方")
	columns.add_child(ally_column.get("column"))
	columns.add_child(enemy_column.get("column"))
	_ally_roster_label = ally_column.get("body")
	_enemy_roster_label = enemy_column.get("body")


func _build_roster_column(title: String) -> Dictionary:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.12, 0.16, 0.78)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.28, 0.4, 0.52, 0.82)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", panel_style)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 10
	column.offset_top = 8
	column.offset_right = -10
	column.offset_bottom = -8
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", FONT_SIZE_PANEL_TITLE)
	column.add_child(heading)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", FONT_SIZE_PANEL_BODY)
	body.text = "暂无"
	column.add_child(body)
	panel.add_child(column)
	return {
		"column": panel,
		"body": body
	}


func _ensure_battle_log_panel() -> void:
	if _battle_log_text_label != null:
		return
	var panel := get_node_or_null("LayoutRoot/RightColumn/BattleLogPanel") as VBoxContainer
	if panel == null:
		return
	var hint_label := get_node_or_null("LayoutRoot/RightColumn/BattleLogPanel/BattleLogHint") as Label
	if hint_label != null:
		hint_label.visible = false
	_battle_log_legend_label = RichTextLabel.new()
	_battle_log_legend_label.name = "BattleLogLegend"
	_battle_log_legend_label.bbcode_enabled = true
	_battle_log_legend_label.fit_content = true
	_battle_log_legend_label.scroll_active = false
	_battle_log_legend_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_legend_label.custom_minimum_size = Vector2(0, 42)
	_battle_log_legend_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_PANEL_BODY - 2)
	_battle_log_legend_label.add_theme_constant_override("line_separation", 2)
	_battle_log_legend_label.text = "[b][color=#DDE6EF]图例：[/color][/b][color=#75E7C2]绿色封印=已拦截[/color] [color=#E9EEF5]|[/color] [color=#F07F7F]红色后果=未响应入场[/color]"
	panel.add_child(_battle_log_legend_label)
	_battle_log_scroll = ScrollContainer.new()
	_battle_log_scroll.name = "BattleLogScroll"
	_battle_log_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_log_scroll.custom_minimum_size = Vector2(0, 180)
	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = Color(0.07, 0.1, 0.14, 0.78)
	scroll_style.border_width_left = 1
	scroll_style.border_width_top = 1
	scroll_style.border_width_right = 1
	scroll_style.border_width_bottom = 1
	scroll_style.border_color = Color(0.34, 0.42, 0.5, 0.9)
	scroll_style.corner_radius_top_left = 6
	scroll_style.corner_radius_top_right = 6
	scroll_style.corner_radius_bottom_right = 6
	scroll_style.corner_radius_bottom_left = 6
	_battle_log_scroll.add_theme_stylebox_override("panel", scroll_style)
	panel.add_child(_battle_log_scroll)
	_battle_log_text_label = RichTextLabel.new()
	_battle_log_text_label.name = "BattleLogRichText"
	_battle_log_text_label.bbcode_enabled = true
	_battle_log_text_label.fit_content = false
	_battle_log_text_label.scroll_active = false
	_battle_log_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_log_text_label.add_theme_constant_override("line_separation", 6)
	_battle_log_text_label.add_theme_font_size_override("normal_font_size", FONT_SIZE_PANEL_BODY)
	_battle_log_scroll.add_child(_battle_log_text_label)


func _refresh_event_timeline() -> void:
	if _event_timeline_label == null:
		return
	var rows := _filter_event_rows(_event_rows)
	var markers := _build_event_timeline_markers(rows)
	_event_timeline_label.text = _build_event_timeline_text(markers)
	_refresh_event_markers(markers)


func _refresh_event_markers(markers: Array) -> void:
	if _event_marker_list == null:
		return
	_event_marker_list.clear()
	_event_marker_ticks.clear()
	for marker in markers:
		var tick := int(marker.get("tick", -1))
		var tick_end := int(marker.get("tick_end", tick))
		var event_type := str(marker.get("type", ""))
		if tick < 0:
			continue
		_event_marker_ticks.append(tick)
		if tick_end > tick:
			_event_marker_list.add_item("第%d~%d帧 %s" % [tick, tick_end, _event_type_display_name(event_type)])
		else:
			_event_marker_list.add_item("第%d帧 %s" % [tick, _event_type_display_name(event_type)])


func _filter_event_rows(rows: Array) -> Array:
	if _event_filter_type == "all":
		return rows
	var filtered: Array = []
	for row in rows:
		if str(row.get("type", "")) == _event_filter_type:
			filtered.append(row)
	return filtered


func _build_event_timeline_markers(rows: Array) -> Array:
	var grouped: Array = []
	var grouped_lookup: Dictionary = {}
	for row in rows:
		var tick := int(row.get("tick", -1))
		if tick < 0:
			continue
		var bucket_start := int(tick / _event_timeline_zoom_step) * _event_timeline_zoom_step
		var bucket_end := bucket_start + _event_timeline_zoom_step - 1
		var event_type := str(row.get("type", ""))
		var marker_key := "%d|%s" % [bucket_start, event_type]
		if not grouped_lookup.has(marker_key):
			grouped_lookup[marker_key] = grouped.size()
			grouped.append({
				"tick": bucket_start,
				"tick_end": bucket_end,
				"type": event_type,
				"count": 1
			})
			continue
		var marker_index := int(grouped_lookup[marker_key])
		var marker: Dictionary = grouped[marker_index]
		marker["count"] = int(marker.get("count", 0)) + 1
		grouped[marker_index] = marker
	return _apply_density_to_markers(grouped)


func _apply_density_to_markers(markers: Array) -> Array:
	var limit := maxi(1, _event_timeline_density_limit)
	if markers.size() <= limit:
		return markers
	var stride := maxi(1, ceili(float(markers.size()) / float(limit)))
	var sampled: Array = []
	for index in range(0, markers.size(), stride):
		sampled.append(markers[index])
	if sampled.size() > limit:
		sampled.resize(limit)
	return sampled


func _build_event_timeline_text(markers: Array) -> String:
	if markers.is_empty():
		return "事件标记：无"
	var marker_texts: PackedStringArray = []
	for row in markers:
		var tick := int(row.get("tick", -1))
		var tick_end := int(row.get("tick_end", tick))
		var event_type := str(row.get("type", ""))
		var count := int(row.get("count", 1))
		var tick_text := "第%d帧" % tick
		if tick_end > tick:
			tick_text = "第%d~%d帧" % [tick, tick_end]
		var marker := "%s %s" % [tick_text, _event_type_display_name(event_type)]
		if count > 1:
			marker = "%s x%d" % [marker, count]
		marker_texts.append(marker)
	return "事件标记：%s" % " | ".join(marker_texts)


func _build_strategy_cast_text(tick: int, rows: Array) -> String:
	var strategy_lines: PackedStringArray = []
	for row in rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var strategy_name := _strategy_display_name(str(row.get("strategy_id", "")))
		var cast_mode := str(row.get("cast_mode", ""))
		if cast_mode == "passive":
			strategy_lines.append("%s（被动生效）" % strategy_name)
		else:
			strategy_lines.append("%s（施放）" % strategy_name)
	if strategy_lines.is_empty():
		return ""
	return "战技施放：%s" % " | ".join(strategy_lines)


func _refresh_strategy_cards(tick: int) -> void:
	_ensure_strategy_card_host()
	if _strategy_card_host == null:
		return
	var states := _build_strategy_card_states(tick)
	var active_ids: Dictionary = {}
	for state in states:
		var strategy_id := str(state.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		active_ids[strategy_id] = true
		var card: Node = _strategy_card_views.get(strategy_id, null)
		if card == null:
			card = STRATEGY_CARD_SCENE.instantiate()
			_strategy_card_host.add_child(card)
			_strategy_card_views[strategy_id] = card
		card.call("apply_state", state)
	for strategy_id in _strategy_card_views.keys():
		if active_ids.has(strategy_id):
			continue
		var stale: Node = _strategy_card_views[strategy_id]
		if stale != null and is_instance_valid(stale):
			stale.queue_free()
		_strategy_card_views.erase(strategy_id)
	var hint_label := get_node_or_null("LayoutRoot/LeftColumn/StrategyPanel/StrategyHint") as Label
	if hint_label != null:
		hint_label.visible = states.is_empty()
		if states.is_empty():
			hint_label.text = "暂无可展示战技"


func _build_strategy_card_states(tick: int) -> Array:
	if _strategy_panel_strategy_ids.is_empty():
		return []
	var states: Array = []
	for strategy_id in _strategy_panel_strategy_ids:
		if strategy_id.is_empty():
			continue
		var cooldown_total := _strategy_cooldown_seconds(strategy_id)
		var last_cast_tick := _last_cast_tick_for_strategy(strategy_id, tick)
		var elapsed_since_cast := 0.0
		if last_cast_tick >= 0:
			elapsed_since_cast = maxf(0.0, float(tick - last_cast_tick) / DEFAULT_TICK_RATE)
		var remaining := 0.0
		if last_cast_tick >= 0 and cooldown_total > 0.0:
			remaining = maxf(0.0, cooldown_total - elapsed_since_cast)
		var ratio := 1.0
		if cooldown_total > 0.0:
			ratio = clampf(1.0 - (remaining / cooldown_total), 0.0, 1.0)
		states.append({
			"strategy_id": strategy_id,
			"name": _strategy_panel_display_name(strategy_id),
			"cooldown_total_seconds": cooldown_total,
			"cooldown_remaining_seconds": remaining,
			"cooldown_ratio": ratio,
			"triggered": last_cast_tick == tick,
			"highlight_alpha": _strategy_highlight_alpha(tick, last_cast_tick)
		})
	return states


func _strategy_cooldown_seconds(strategy_id: String) -> float:
	return float(_strategy_panel_cooldown_seconds_by_id.get(strategy_id, 0.0))


func _last_cast_tick_for_strategy(strategy_id: String, current_tick: int) -> int:
	var ticks: Array = _strategy_cast_ticks_by_id.get(strategy_id, [])
	if not (ticks is Array) or ticks.is_empty():
		return -1
	var left: int = 0
	var right: int = ticks.size() - 1
	var last_tick: int = -1
	while left <= right:
		var middle := int((left + right) / 2)
		var tick := int(ticks[middle])
		if tick <= current_tick:
			last_tick = tick
			left = middle + 1
		else:
			right = middle - 1
	return last_tick


func _is_strategy_triggered_at_tick(strategy_id: String, tick: int) -> bool:
	return _last_cast_tick_for_strategy(strategy_id, tick) == tick


func _rebuild_strategy_card_runtime_cache(battle_setup: Dictionary, rows: Array) -> void:
	_strategy_panel_strategy_ids.clear()
	_strategy_panel_cooldown_seconds_by_id.clear()
	_strategy_panel_display_name_by_id.clear()
	_strategy_cast_ticks_by_id.clear()
	_strategy_panel_effect_type_by_id.clear()
	if battle_setup.is_empty():
		return
	var content := BATTLE_CONTENT.new()
	for raw_strategy_id in battle_setup.get("strategy_ids", []):
		var strategy_id := str(raw_strategy_id)
		if strategy_id.is_empty():
			continue
		_strategy_panel_strategy_ids.append(strategy_id)
		if _strategy_panel_cooldown_seconds_by_id.has(strategy_id):
			continue
		var strategy_def: Dictionary = content.get_strategy(strategy_id)
		_strategy_panel_cooldown_seconds_by_id[strategy_id] = maxf(0.0, float(strategy_def.get("cooldown", 0.0)))
		_strategy_panel_display_name_by_id[strategy_id] = String(strategy_def.get("name", _display_name_resolver.strategy_name(strategy_id)))
		_strategy_panel_effect_type_by_id[strategy_id] = str((strategy_def.get("effect_def", {}) as Dictionary).get("type", ""))
	content.free()
	for row in rows:
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var strategy_id := str(row.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		var ticks: Array = _strategy_cast_ticks_by_id.get(strategy_id, [])
		ticks.append(int(row.get("tick", -1)))
		_strategy_cast_ticks_by_id[strategy_id] = ticks
	for strategy_id in _strategy_cast_ticks_by_id.keys():
		var ticks: Array = _strategy_cast_ticks_by_id[strategy_id]
		ticks.sort()
		_strategy_cast_ticks_by_id[strategy_id] = ticks


func _strategy_panel_display_name(strategy_id: String) -> String:
	return String(_strategy_panel_display_name_by_id.get(strategy_id, _strategy_display_name(strategy_id)))


func _refresh_battle_overview() -> void:
	if _battle_overview_label == null:
		return
	if _battle_result.is_empty() and _timeline.is_empty():
		_battle_overview_label.text = "战况总览：数据准备中"
		return
	var victory_text := "未知"
	if not _battle_result.is_empty():
		victory_text = "胜利" if bool(_battle_result.get("victory", false)) else "失败"
	var survivors_count := int((_battle_result.get("survivors", []) as Array).size())
	var casualties_count := int((_battle_result.get("casualties", []) as Array).size())
	var triggered_events_count := int((_battle_result.get("triggered_events", []) as Array).size())
	var strategy_cast_count := _count_strategy_casts(_event_rows)
	var alive_counts := _count_alive_sides(_current_entities)
	var current_index := maxi(0, _current_frame_index)
	var total_frames := _timeline.size()
	_battle_overview_label.text = "战况总览｜胜负：%s｜进度：%d/%d帧\n当前存活：我方%d 敌方%d｜阵亡：%d｜触发事件：%d｜战技施放：%d" % [
		victory_text,
		current_index,
		total_frames,
		int(alive_counts.get("ally_team", 0)),
		int(alive_counts.get("enemy", 0)),
		casualties_count,
		triggered_events_count,
		strategy_cast_count
	]
	if survivors_count > 0 and total_frames == 0:
		_battle_overview_label.text += "\n结果存活数：%d" % survivors_count


func _count_strategy_casts(rows: Array) -> int:
	var count := 0
	for row in rows:
		if str(row.get("type", "")) == "strategy_cast":
			count += 1
	return count


func _strategy_highlight_alpha(current_tick: int, cast_tick: int) -> float:
	if cast_tick < 0 or cast_tick > current_tick:
		return 0.0
	var age := current_tick - cast_tick
	if age >= STRATEGY_HIGHLIGHT_LINGER_TICKS:
		return 0.0
	return clampf(1.0 - (float(age) / float(STRATEGY_HIGHLIGHT_LINGER_TICKS)), 0.0, 1.0)


func _strategy_highlight_alpha_for_tick(cast_tick: int) -> float:
	return _strategy_highlight_alpha(_current_tick, cast_tick)


func _strategy_popup_state_for_tick(current_tick: int) -> Dictionary:
	var cast := _latest_strategy_cast_snapshot(current_tick)
	var cast_tick := int(cast.get("tick", -1))
	if cast_tick < 0:
		return {
			"text": "",
			"alpha": 0.0,
			"scale": 1.0
		}
	var age := current_tick - cast_tick
	if age < 0 or age >= STRATEGY_NAME_POPUP_LINGER_TICKS:
		return {
			"text": "",
			"alpha": 0.0,
			"scale": 1.0
		}
	var life_t := float(age) / float(maxi(1, STRATEGY_NAME_POPUP_LINGER_TICKS - 1))
	var alpha := pow(1.0 - life_t, 1.55)
	var scale_factor := 1.0 + STRATEGY_NAME_POPUP_SCALE_BOOST * (1.0 - life_t * 0.72)
	return {
		"text": String(cast.get("text", "")),
		"alpha": clampf(alpha, 0.0, 1.0),
		"scale": maxf(1.0, scale_factor)
	}


func _strategy_screen_flash_alpha(current_tick: int) -> float:
	var cast := _latest_strategy_cast_snapshot(current_tick)
	var cast_tick := int(cast.get("tick", -1))
	if cast_tick < 0:
		return 0.0
	var age := current_tick - cast_tick
	if age < 0 or age >= STRATEGY_FLASH_LINGER_TICKS:
		return 0.0
	var life_t := float(age) / float(maxi(1, STRATEGY_FLASH_LINGER_TICKS - 1))
	return STRATEGY_FLASH_MAX_ALPHA * pow(1.0 - life_t, 2.0)


func _latest_strategy_cast_snapshot(current_tick: int) -> Dictionary:
	var latest_tick := -1
	var names: PackedStringArray = []
	for row in _event_rows:
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var tick := int(row.get("tick", -1))
		if tick > current_tick:
			continue
		if tick <= latest_tick:
			if tick == latest_tick:
				var same_tick_name := _strategy_display_name(str(row.get("strategy_id", "")))
				if not same_tick_name.is_empty():
					names.append(same_tick_name)
			continue
		latest_tick = tick
		names.clear()
		var display_name := _strategy_display_name(str(row.get("strategy_id", "")))
		if not display_name.is_empty():
			names.append(display_name)
	if latest_tick < 0:
		return {"tick": -1, "text": ""}
	if names.is_empty():
		names.append("战技")
	return {
		"tick": latest_tick,
		"text": "「%s」" % " / ".join(names)
	}


func _strategy_target_highlight_alpha(entity_id: String, current_tick: int) -> float:
	if entity_id.is_empty():
		return 0.0
	var best_alpha := 0.0
	for row in _event_rows:
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var cast_tick := int(row.get("tick", -1))
		var alpha := _strategy_highlight_alpha(current_tick, cast_tick)
		if alpha <= 0.0:
			continue
		var strategy_id := str(row.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		var target_ids := _strategy_target_entity_ids(strategy_id)
		if not target_ids.has(entity_id):
			continue
		best_alpha = maxf(best_alpha, alpha)
	return best_alpha


func _count_alive_sides(entities: Array) -> Dictionary:
	var counts := {
		"ally_team": 0,
		"enemy": 0
	}
	for entity in entities:
		if not bool(entity.get("alive", false)):
			continue
		var side := str(entity.get("side", ""))
		if side == "enemy":
			counts["enemy"] = int(counts.get("enemy", 0)) + 1
		else:
			counts["ally_team"] = int(counts.get("ally_team", 0)) + 1
	return counts


func _refresh_tick_summary(tick: int, event_rows: Array) -> void:
	if _tick_summary_label == null:
		return
	_tick_summary_label.text = _build_tick_summary_text(tick, event_rows)


func _build_tick_summary_text(tick: int, rows: Array) -> String:
	return _battle_report_formatter.build_tick_brief(rows, tick, _event_filter_type)


func _refresh_detail_log(tick: int, rows: Array) -> void:
	if _detail_log_list == null:
		return
	_detail_log_list.clear()
	var detail_lines := (
		_battle_report_formatter.build_recent_detail(rows, tick, _event_filter_type, 12)
		if _detail_log_expanded
		else _battle_report_formatter.build_tick_detail(rows, tick, _event_filter_type)
	)
	for line in detail_lines:
		_detail_log_list.add_item(String(line))
	_refresh_detail_log_visibility()


func _refresh_detail_log_visibility() -> void:
	if _detail_toggle_button == null or _detail_log_list == null:
		return
	_detail_toggle_button.text = "收起战术明细（最近12条）" if _detail_log_expanded else "展开战术明细（最近12条）"
	_detail_log_list.visible = _detail_log_expanded


func _refresh_alive_roster_panel() -> void:
	_ensure_alive_roster_panel()
	if _ally_roster_label == null or _enemy_roster_label == null:
		return
	var sections := _build_alive_roster_sections()
	_ally_roster_label.text = _roster_lines_text(sections.get("ally", []))
	_enemy_roster_label.text = _roster_lines_text(sections.get("enemy", []))


func _build_alive_roster_sections() -> Dictionary:
	var ally_lines: Array[String] = []
	var enemy_lines: Array[String] = []
	for entity in _panel_entities():
		if not bool(entity.get("alive", false)):
			continue
		var side := str(entity.get("side", ""))
		var line := "%s %s" % [_entity_display_name(entity), _entity_hp_text(entity)]
		if side == "enemy":
			enemy_lines.append(line)
		else:
			ally_lines.append(line)
	return {
		"ally": ally_lines,
		"enemy": enemy_lines
	}


func _panel_entities() -> Array:
	if not _current_entities.is_empty():
		return _current_entities
	if _timeline.is_empty():
		return []
	var first_frame := _timeline[0] as Dictionary
	return first_frame.get("entities", [])


func _entity_display_name(entity: Dictionary) -> String:
	var display_name := str(entity.get("display_name", ""))
	if not display_name.is_empty() and not display_name.begins_with("未知"):
		return display_name
	var unit_id := str(entity.get("unit_id", ""))
	if not unit_id.is_empty():
		var unit_display_name := _display_name_resolver.unit_name_from_unit_id(unit_id)
		if not unit_display_name.begins_with("未知"):
			return unit_display_name
	if not display_name.is_empty():
		return display_name
	return _unit_display_name_from_entity_id(str(entity.get("entity_id", "")))


func _entity_hp_text(entity: Dictionary) -> String:
	var hp := int(round(float(entity.get("hp", 0.0))))
	var max_hp := int(round(float(entity.get("max_hp", 0.0))))
	if max_hp <= 0:
		return "%d" % hp
	return "%d/%d" % [hp, max_hp]


func _roster_lines_text(lines: Array) -> String:
	if lines.is_empty():
		return "暂无"
	return "\n".join(PackedStringArray(lines))


func _refresh_battle_log_panel() -> void:
	_ensure_battle_log_panel()
	if _battle_log_text_label == null:
		return
	_battle_log_text_label.clear()
	_battle_log_text_label.append_text(_build_battle_log_rich_text())


func _build_battle_log_lines(limit: int = 18) -> Array[String]:
	# Use tagged version for key events
	var key_lines := _battle_report_formatter.build_key_event_lines_with_tags(_event_rows, _display_tick(), 8)
	var normal_lines := _battle_report_formatter.build_recent_detail(_event_rows, _display_tick(), "all", limit)

	# Generate phase summary cards (between key events and regular logs)
	var phase_cards := _battle_report_formatter.build_phase_summary_cards(_timeline, _event_rows)

	var lines: Array[String] = ["关键事件"]
	for line in key_lines:
		lines.append("%s %s" % [_log_prefix_for_line(String(line)), String(line)])

	# Insert phase summary cards
	if not phase_cards.is_empty():
		lines.append("")
		lines.append("阶段汇总")
		# Strip BBCode from cards for plain text version
		for card in phase_cards:
			var plain_card := _strip_bbcode(card)
			lines.append(plain_card)

	lines.append("")
	lines.append("普通日志")
	for line in normal_lines:
		lines.append("%s %s" % [_log_prefix_for_line(String(line)), String(line)])
	return lines


func _strip_bbcode(text: String) -> String:
	var result := text
	# Remove [color=...] tags
	while true:
		var start_idx := result.find("[color=")
		if start_idx == -1:
			break
		var end_idx := result.find("]", start_idx)
		if end_idx == -1:
			break
		result = result.substr(0, start_idx) + result.substr(end_idx + 1)
	# Remove [/color] tags
	result = result.replace("[/color]", "")
	# Remove [b] and [/b] tags
	result = result.replace("[b]", "").replace("[/b]", "")
	return result


func _build_battle_log_rich_text(limit: int = 18) -> String:
	# Use tagged version for key events
	var key_lines := _battle_report_formatter.build_key_event_lines_with_tags(_event_rows, _display_tick(), 8)
	var normal_lines := _battle_report_formatter.build_recent_detail(_event_rows, _display_tick(), "all", limit)

	# Generate phase summary cards (between key events and regular logs)
	var phase_cards := _battle_report_formatter.build_phase_summary_cards(_timeline, _event_rows)

	var rows: PackedStringArray = []
	rows.append("[b][color=#F2F5F8]关键事件[/color][/b]")
	for line in key_lines:
		var text := String(line)
		rows.append("[color=%s]▌[/color] [color=#EAF0F5]%s[/color]" % [LOG_BAR_COLOR_KEY, text])

	# Insert phase summary cards
	if not phase_cards.is_empty():
		rows.append("")
		rows.append("[b][color=#F2F5F8]阶段汇总[/color][/b]")
		for card in phase_cards:
			rows.append(card)

	rows.append("")
	rows.append("[b][color=#F2F5F8]普通日志[/color][/b]")
	for line in normal_lines:
		var text := String(line)
		rows.append("[color=%s]▌[/color] [color=#DFE7EF]%s[/color]" % [_log_color_for_line(text), text])
	return "\n".join(rows)


func _log_prefix_for_line(line: String) -> String:
	return "▌"


func _log_color_for_line(line: String) -> String:
	if line.find("倒下") != -1:
		return LOG_BAR_COLOR_DOWN
	if line.find("施放") != -1:
		return LOG_BAR_COLOR_CAST
	if line.find("预警") != -1 or line.find("秒后") != -1:
		return LOG_BAR_COLOR_WARNING
	if line.find("已响应") != -1:
		return "#75E7C2"
	if line.find("未响应") != -1 or line.find("关键") != -1:
		return LOG_BAR_COLOR_KEY
	return LOG_BAR_COLOR_DEFAULT


func _display_tick() -> int:
	if _current_frame_index >= 0 or _timeline.is_empty():
		return _current_tick
	return int((_timeline[0] as Dictionary).get("tick", _current_tick))


func _build_event_row_text(row: Dictionary) -> String:
	var event_type := str(row.get("type", ""))
	match event_type:
		"strategy_cast":
			return "%s：%s" % [_event_type_display_name(event_type), _strategy_display_name(str(row.get("strategy_id", "")))]
		"event_warning":
			return "%s：%s" % [_event_type_display_name(event_type), _event_display_name(str(row.get("event_id", "")))]
		"event_resolve":
			var responded := bool(row.get("responded", false))
			var respond_text := "已响应" if responded else "未响应"
			return "%s：%s（%s）" % [_event_type_display_name(event_type), _event_display_name(str(row.get("event_id", ""))), respond_text]
		"event_unresolved_effect":
			return "%s：%s" % [_event_type_display_name(event_type), _event_display_name(str(row.get("event_id", "")))]
		"ally_down", "hero_down", "enemy_down":
			return "%s：%s" % [_event_type_display_name(event_type), _unit_display_name_from_entity_id(str(row.get("entity_id", "")))]
		_:
			if row.has("event_id"):
				return "%s：%s" % [_event_type_display_name(event_type), _event_display_name(str(row.get("event_id", "")))]
			return "%s：%s" % [_event_type_display_name(event_type), _unit_display_name_from_entity_id(str(row.get("entity_id", "")))]


func _seek_to_tick(target_tick: int) -> void:
	if _timeline.is_empty():
		return
	for index in range(_timeline.size()):
		var frame: Dictionary = _timeline[index]
		if int(frame.get("tick", -1)) >= target_tick:
			_seek_to_frame(index)
			return
	_seek_to_frame(_timeline.size() - 1)


func _session_state() -> Node:
	return get_node_or_null("/root/SessionState")


func _app_router() -> Node:
	return get_node_or_null("/root/AppRouter")


## Task 1 keeps two observe UI ownership layers on purpose:
## - LayoutRoot is the new quadrant baseline that readability/layout tests target.
## - EventPanel still owns the live battle report controls for compatibility and will
##   be migrated into the quadrant containers in later tasks.
func get_layout_ratio_snapshot() -> Dictionary:
	var layout_nodes := _layout_ratio_nodes()
	return {
		"left": _ratio_from_horizontal_layout(layout_nodes),
		"right_top": _ratio_from_vertical_layout(layout_nodes)
	}


func _layout_ratio_nodes() -> Dictionary:
	return {
		"layout_root": get_node_or_null("LayoutRoot") as Control,
		"left_column": get_node_or_null("LayoutRoot/LeftColumn") as Control,
		"right_column": get_node_or_null("LayoutRoot/RightColumn") as Control,
		"alive_roster_panel": get_node_or_null("LayoutRoot/RightColumn/AliveRosterPanel") as Control,
		"battle_log_panel": get_node_or_null("LayoutRoot/RightColumn/BattleLogPanel") as Control
	}


func _ratio_from_horizontal_layout(layout_nodes: Dictionary) -> float:
	var layout_root := layout_nodes.get("layout_root", null) as Control
	var left_column := layout_nodes.get("left_column", null) as Control
	var right_column := layout_nodes.get("right_column", null) as Control
	if layout_root != null and layout_root.size.x > 0.0 and left_column != null and left_column.size.x > 0.0:
		return left_column.size.x / layout_root.size.x
	if left_column == null or right_column == null:
		return 0.0
	var left_stretch := maxf(left_column.size_flags_stretch_ratio, 0.0)
	var right_stretch := maxf(right_column.size_flags_stretch_ratio, 0.0)
	var total_stretch := left_stretch + right_stretch
	if total_stretch <= 0.0:
		return 0.0
	return left_stretch / total_stretch


func _ratio_from_vertical_layout(layout_nodes: Dictionary) -> float:
	var right_column := layout_nodes.get("right_column", null) as Control
	var alive_roster_panel := layout_nodes.get("alive_roster_panel", null) as Control
	var battle_log_panel := layout_nodes.get("battle_log_panel", null) as Control
	if right_column != null and right_column.size.y > 0.0 and alive_roster_panel != null and alive_roster_panel.size.y > 0.0:
		return alive_roster_panel.size.y / right_column.size.y
	if alive_roster_panel == null or battle_log_panel == null:
		return 0.0
	var top_stretch := maxf(alive_roster_panel.size_flags_stretch_ratio, 0.0)
	var bottom_stretch := maxf(battle_log_panel.size_flags_stretch_ratio, 0.0)
	var total_stretch := top_stretch + bottom_stretch
	if total_stretch <= 0.0:
		return 0.0
	return top_stretch / total_stretch


func _event_type_display_name(event_type: String) -> String:
	match event_type:
		"event_warning":
			return "事件预警"
		"event_resolve":
			return "事件结算"
		"event_unresolved_effect":
			return "未响应后果"
		"strategy_cast":
			return "战技施放"
		"ally_down":
			return "友军倒下"
		"hero_down":
			return "英雄倒下"
		"enemy_down":
			return "敌方倒下"
		_:
			return "其他事件"


func _event_display_name(event_id: String) -> String:
	return _display_name_resolver.event_name(event_id)


func _strategy_display_name(strategy_id: String) -> String:
	return _display_name_resolver.strategy_name(strategy_id)


func _unit_display_name_from_entity_id(entity_id: String) -> String:
	return _display_name_resolver.unit_name_from_entity_id(entity_id)
