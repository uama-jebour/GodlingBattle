extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const TOKEN_VIEW_SCENE := preload("res://scenes/observe/token_view.tscn")
const BATTLE_MAP_SCENE := preload("res://scenes/observe/battle_map_view.tscn")
const FRAME_STEP_SECONDS := 0.05

var _timeline: Array = []
var _frame_index := 0
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
var _token_views: Dictionary = {}
var _event_rows: Array = []
var _battle_map: Control
@onready var _pause_button: Button = $PlaybackPanel/PauseButton
@onready var _speed_select: OptionButton = $PlaybackPanel/SpeedSelect


func _ready() -> void:
	_bind_playback_controls()
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
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
	_playback_accumulator = 0.0
	_is_paused = false
	_playback_speed = 1.0
	_select_speed_by_value(_playback_speed)
	_is_playing = not _timeline.is_empty()
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
	if _playback_accumulator < FRAME_STEP_SECONDS:
		return
	_playback_accumulator = 0.0
	var finished := advance_playback_step()
	if finished:
		_is_playing = false
		_refresh_playback_controls()
		set_process(false)
		var app_router := _app_router()
		if app_router != null:
			app_router.goto_result()


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
	if not _speed_select.item_selected.is_connected(_on_speed_selected):
		_speed_select.item_selected.connect(_on_speed_selected)


func _refresh_playback_controls() -> void:
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
	var frame = _timeline[_frame_index]
	apply_timeline_frame(frame)
	_frame_index += 1
	return _frame_index >= _timeline.size()


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
	for row in event_rows:
		if int(row.get("tick", -1)) != tick:
			continue
		messages.append("事件 %s:%s" % [
			str(row.get("type", "")),
			str(row.get("event_id", row.get("entity_id", "")))
		])
	if messages.is_empty():
		_event_label.text = ""
		return
	_event_label.text = " | ".join(messages)


func get_tick_text() -> String:
	_ensure_hud()
	return _tick_label.text


func get_event_text() -> String:
	_ensure_hud()
	return _event_label.text


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


func _session_state() -> Node:
	return get_node_or_null("/root/SessionState")


func _app_router() -> Node:
	return get_node_or_null("/root/AppRouter")
