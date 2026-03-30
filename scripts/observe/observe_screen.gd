extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const TOKEN_VIEW_SCENE := preload("res://scenes/observe/token_view.tscn")
const BATTLE_MAP_SCENE := preload("res://scenes/observe/battle_map_view.tscn")
const FRAME_STEP_SECONDS := 0.05
const JUMP_FRAME_DELTA := 10

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
var _battle_map: Control
@onready var _pause_button: Button = $PlaybackPanel/PauseButton
@onready var _step_back_button: Button = $PlaybackPanel/StepBackButton
@onready var _progress_slider: HSlider = $PlaybackPanel/ProgressSlider
@onready var _step_forward_button: Button = $PlaybackPanel/StepForwardButton
@onready var _speed_select: OptionButton = $PlaybackPanel/SpeedSelect
@onready var _event_filter_select: OptionButton = $EventPanel/EventFilterSelect
@onready var _event_timeline_zoom_select: OptionButton = $EventPanel/EventTimelineZoomSelect
@onready var _event_timeline_density_select: OptionButton = $EventPanel/EventTimelineDensitySelect
@onready var _event_timeline_label: Label = $EventPanel/EventTimelineLabel
@onready var _event_marker_list: ItemList = $EventPanel/EventMarkerList
var _syncing_progress_slider := false
var _event_filter_type := "all"
var _event_timeline_zoom_step := 1
var _event_timeline_density_limit := 64
var _event_marker_ticks: Array[int] = []


func _ready() -> void:
	_bind_playback_controls()
	_bind_event_filter_controls()
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
		_event_rows = []
		_refresh_event_timeline()
		_refresh_progress_slider()
		_refresh_playback_controls()
		return
	if session_state.last_timeline.is_empty():
		play_battle(session_state.battle_setup)
	_event_rows = session_state.last_battle_result.get("log_entries", []).duplicate(true)
	_ensure_token_host()
	_ensure_hud()
	_ensure_map()
	_timeline = session_state.last_timeline.duplicate(true)
	_frame_index = 0
	_current_frame_index = -1
	_playback_accumulator = 0.0
	_is_paused = false
	_playback_speed = 1.0
	_select_speed_by_value(_playback_speed)
	_is_playing = not _timeline.is_empty()
	_refresh_event_timeline()
	_refresh_progress_slider()
	_refresh_playback_controls()
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
		_speed_select.add_item("1x", 0)
		_speed_select.set_item_metadata(0, 1.0)
		_speed_select.add_item("2x", 1)
		_speed_select.set_item_metadata(1, 2.0)
		_speed_select.add_item("4x", 2)
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
		_event_timeline_zoom_select.add_item("时间轴缩放：1x", 0)
		_event_timeline_zoom_select.set_item_metadata(0, 1)
		_event_timeline_zoom_select.add_item("时间轴缩放：2x", 1)
		_event_timeline_zoom_select.set_item_metadata(1, 2)
		_event_timeline_zoom_select.add_item("时间轴缩放：5x", 2)
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
			"position": _entity_position(entity)
		})
	return rows


func advance_playback_step() -> bool:
	if _frame_index >= _timeline.size():
		return true
	var frame: Dictionary = _timeline[_frame_index]
	apply_timeline_frame(frame)
	_current_frame_index = _frame_index
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
	apply_timeline_frame(frame)
	_current_frame_index = target_index
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
	_tick_label.text = "Tick %d" % tick
	var messages: Array[String] = []
	for row in _filter_event_rows(event_rows):
		if int(row.get("tick", -1)) != tick:
			continue
		messages.append("事件 %s:%s" % [
			str(row.get("type", "")),
			str(row.get("event_id", row.get("entity_id", "")))
		])
	if messages.is_empty():
		_event_label.text = ""
	else:
		_event_label.text = " | ".join(messages)
	_strategy_cast_label.text = _build_strategy_cast_text(tick, event_rows)


func get_tick_text() -> String:
	_ensure_hud()
	return _tick_label.text


func get_event_text() -> String:
	_ensure_hud()
	return _event_label.text


func get_strategy_cast_text() -> String:
	_ensure_hud()
	return _strategy_cast_label.text


func get_event_timeline_text() -> String:
	if _event_timeline_label == null:
		return ""
	return _event_timeline_label.text


func get_event_timeline_marker_count() -> int:
	return _event_marker_ticks.size()


func _hp_ratio(entity: Dictionary) -> float:
	var hp := float(entity.get("hp", 0.0))
	var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
	return clampf(hp / max_hp, 0.0, 1.0)


func _entity_position(entity: Dictionary) -> Vector2:
	var raw = entity.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _ensure_token_host() -> void:
	if _token_host != null:
		return
	_token_host = Control.new()
	_token_host.name = "TokenHost"
	_token_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_token_host)

	_ally_layer = Control.new()
	_ally_layer.name = "AllyLayer"
	_ally_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_token_host.add_child(_ally_layer)

	_enemy_layer = Control.new()
	_enemy_layer.name = "EnemyLayer"
	_enemy_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_token_host.add_child(_enemy_layer)


func _ensure_hud() -> void:
	if _hud_root != null:
		return
	_hud_root = Control.new()
	_hud_root.name = "HudRoot"
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hud_root)

	_tick_label = Label.new()
	_tick_label.name = "TickLabel"
	_tick_label.position = Vector2(20, 20)
	_tick_label.text = "Tick 0"
	_hud_root.add_child(_tick_label)

	_event_label = Label.new()
	_event_label.name = "EventLabel"
	_event_label.position = Vector2(20, 48)
	_event_label.text = ""
	_hud_root.add_child(_event_label)

	_strategy_cast_label = Label.new()
	_strategy_cast_label.name = "StrategyCastLabel"
	_strategy_cast_label.position = Vector2(20, 76)
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
			_event_marker_list.add_item("Tick %d~%d %s" % [tick, tick_end, event_type])
		else:
			_event_marker_list.add_item("Tick %d %s" % [tick, event_type])


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
		var tick_text := "t%d" % tick
		if tick_end > tick:
			tick_text = "t%d~%d" % [tick, tick_end]
		var marker := "%s %s" % [tick_text, event_type]
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
		strategy_ids.append(str(row.get("strategy_id", "")))
	if strategy_ids.is_empty():
		return ""
	return "战技施放：%s" % " | ".join(strategy_ids)


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
