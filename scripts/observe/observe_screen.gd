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
var _token_host: Control
var _ally_layer: Control
var _enemy_layer: Control
var _hud_root: Control
var _tick_label: Label
var _event_label: Label
var _token_views: Dictionary = {}
var _event_rows: Array = []
var _battle_map: Control


func _ready() -> void:
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
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
	_is_playing = not _timeline.is_empty()
	if _is_playing:
		set_process(true)
	else:
		var app_router := _app_router()
		if app_router != null:
			app_router.goto_result()


func _process(delta: float) -> void:
	if not _is_playing:
		return
	_playback_accumulator += delta
	if _playback_accumulator < FRAME_STEP_SECONDS:
		return
	_playback_accumulator = 0.0
	var finished := advance_playback_step()
	if finished:
		_is_playing = false
		set_process(false)
		var app_router := _app_router()
		if app_router != null:
			app_router.goto_result()


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
