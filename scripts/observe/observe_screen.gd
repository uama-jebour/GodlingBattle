extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const TOKEN_VIEW_SCENE := preload("res://scenes/observe/token_view.tscn")
const BATTLE_MAP_SCENE := preload("res://scenes/observe/battle_map_view.tscn")
const STRATEGY_CARD_SCENE := preload("res://scenes/observe/strategy_card_view.tscn")
const BATTLEFIELD_LAYOUT_SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")
const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")
const BATTLE_REPORT_FORMATTER := preload("res://scripts/observe/battle_report_formatter.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")
const FRAME_STEP_SECONDS := 0.05
const JUMP_FRAME_DELTA := 10
const DEATH_MARKER_LINGER_TICKS := 12
const DEFAULT_TICK_RATE := 10.0

var _timeline: Array = []
var _frame_index := 0
var _current_frame_index := -1
var _current_tick := 0
var _current_entities: Array = []
var _playback_accumulator := 0.0
var _is_playing := false
var _is_paused := false
var _playback_speed := 1.0
var _token_host: Control
var _ally_layer: Control
var _enemy_layer: Control
var _hud_root: Control
var _tick_label: Label
var _event_label: Label
var _strategy_cast_label: Label
var _token_views: Dictionary = {}
var _event_rows: Array = []
var _battle_result: Dictionary = {}
var _battle_map: Control
var _battlefield_layout_solver := BATTLEFIELD_LAYOUT_SOLVER.new()
var _display_name_resolver := DISPLAY_NAME_RESOLVER.new()
var _battle_report_formatter := BATTLE_REPORT_FORMATTER.new()
var _strategy_panel_strategy_ids: Array[String] = []
var _strategy_panel_cooldown_seconds_by_id: Dictionary = {}
var _strategy_panel_display_name_by_id: Dictionary = {}
var _strategy_cast_ticks_by_id: Dictionary = {}
var _strategy_card_host: HBoxContainer
var _strategy_card_views: Dictionary = {}
var _ally_roster_label: Label
var _enemy_roster_label: Label
var _battle_log_text_label: RichTextLabel
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
	_ensure_strategy_card_host()
	_ensure_alive_roster_panel()
	_ensure_battle_log_panel()
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
	_playback_speed = 1.0
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
	if _is_playing:
		set_process(true)
	else:
		var app_router := _app_router()
		if app_router != null:
			app_router.goto_result()


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
		_speed_select.add_item("1倍速", 0)
		_speed_select.set_item_metadata(0, 1.0)
		_speed_select.add_item("2倍速", 1)
		_speed_select.set_item_metadata(1, 2.0)
		_speed_select.add_item("4倍速", 2)
		_speed_select.set_item_metadata(2, 4.0)
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
	var snapshot := build_token_snapshot()
	sync_token_views(snapshot)
	_ensure_map()
	_battle_map.call("set_snapshot", snapshot)
	update_hud_for_tick(_current_tick, _event_rows)


func build_token_snapshot() -> Array:
	var rows: Array = []
	for entity in _current_entities:
		rows.append({
			"entity_id": str(entity.get("entity_id", "")),
			"display_name": str(entity.get("display_name", "")),
			"side": str(entity.get("side", "")),
			"hp_ratio": _hp_ratio(entity),
			"position": _entity_position(entity),
			"visual_flags": _build_visual_flags(entity)
		})
	return _battlefield_layout_solver.resolve(rows, _battlefield_bounds())


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
	_refresh_tick_summary(tick, event_rows)
	_refresh_detail_log(tick, event_rows)
	_refresh_battle_overview()
	_refresh_strategy_cards(tick)
	_refresh_alive_roster_panel()
	_refresh_battle_log_panel()


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


func _build_visual_flags(entity: Dictionary) -> Dictionary:
	var entity_id := str(entity.get("entity_id", ""))
	var hp_now := float(entity.get("hp", 0.0))
	var hp_prev := float(_prev_hp_by_entity.get(entity_id, hp_now))
	var is_dead := not bool(entity.get("alive", false))
	return {
		"is_hit": hp_now < hp_prev,
		"is_affected": _has_tick_effect(entity_id, _current_tick),
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
		"is_affected": false,
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


func _battlefield_bounds() -> Rect2:
	if _battle_map != null:
		var battle_map_rect := _battle_map.get_rect()
		if battle_map_rect.size.x > 0.0 and battle_map_rect.size.y > 0.0:
			return battle_map_rect
	var screen_rect := get_rect()
	if screen_rect.size.x > 0.0 and screen_rect.size.y > 0.0:
		return screen_rect
	return Rect2(0, 0, 640, 360)


func _ensure_token_host() -> void:
	if _token_host != null:
		return
	_token_host = Control.new()
	_token_host.name = "TokenHost"
	_token_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_token_host)

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
	if _hud_root != null:
		return
	_hud_root = Control.new()
	_hud_root.name = "HudRoot"
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hud_root)

	var hud_bg := ColorRect.new()
	hud_bg.name = "HudBg"
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_bg.position = Vector2(14, 14)
	hud_bg.size = Vector2(1400, 170)
	hud_bg.color = Color(0.05, 0.08, 0.11, 0.78)
	_hud_root.add_child(hud_bg)

	_tick_label = Label.new()
	_tick_label.name = "TickLabel"
	_tick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tick_label.position = Vector2(20, 20)
	_tick_label.text = "第0帧"
	_tick_label.add_theme_font_size_override("font_size", 42)
	_hud_root.add_child(_tick_label)

	_event_label = Label.new()
	_event_label.name = "EventLabel"
	_event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_label.position = Vector2(24, 72)
	_event_label.custom_minimum_size = Vector2(1360, 42)
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_label.add_theme_font_size_override("font_size", 28)
	_event_label.text = ""
	_hud_root.add_child(_event_label)

	_strategy_cast_label = Label.new()
	_strategy_cast_label.name = "StrategyCastLabel"
	_strategy_cast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strategy_cast_label.position = Vector2(24, 114)
	_strategy_cast_label.custom_minimum_size = Vector2(1360, 42)
	_strategy_cast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_strategy_cast_label.add_theme_font_size_override("font_size", 28)
	_strategy_cast_label.text = ""
	_hud_root.add_child(_strategy_cast_label)


func _ensure_map() -> void:
	if _battle_map != null:
		return
	_battle_map = BATTLE_MAP_SCENE.instantiate()
	_battle_map.name = "BattleMap"
	_battle_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_battle_map)
	move_child(_battle_map, 0)


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
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 16)
	body.text = "暂无"
	column.add_child(body)
	return {
		"column": column,
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
	_battle_log_text_label = RichTextLabel.new()
	_battle_log_text_label.name = "BattleLogRichText"
	_battle_log_text_label.bbcode_enabled = false
	_battle_log_text_label.fit_content = false
	_battle_log_text_label.scroll_active = true
	_battle_log_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_log_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_battle_log_text_label.custom_minimum_size = Vector2(0, 180)
	_battle_log_text_label.add_theme_font_size_override("normal_font_size", 18)
	panel.add_child(_battle_log_text_label)


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
	var strategy_ids: PackedStringArray = []
	for row in rows:
		if int(row.get("tick", -1)) != tick:
			continue
		if str(row.get("type", "")) != "strategy_cast":
			continue
		strategy_ids.append(_strategy_display_name(str(row.get("strategy_id", ""))))
	if strategy_ids.is_empty():
		return ""
	return "战技施放：%s" % " | ".join(strategy_ids)


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
			"triggered": last_cast_tick == tick
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
	_battle_log_text_label.text = get_battle_log_text()


func _build_battle_log_lines(limit: int = 18) -> Array[String]:
	return _battle_report_formatter.build_recent_detail(_event_rows, _display_tick(), "all", limit)


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
