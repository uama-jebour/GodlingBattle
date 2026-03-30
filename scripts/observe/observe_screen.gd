extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const TOKEN_VIEW_SCENE := preload("res://scenes/observe/token_view.tscn")
const FRAME_STEP_SECONDS := 0.05

var _timeline: Array = []
var _frame_index := 0
var _current_tick := 0
var _current_entities: Array = []
var _playback_accumulator := 0.0
var _is_playing := false
var _token_host: Control
var _token_views: Dictionary = {}


func _ready() -> void:
	if SessionState.battle_setup.is_empty():
		return
	if SessionState.last_timeline.is_empty():
		play_battle(SessionState.battle_setup)
	_ensure_token_host()
	_timeline = SessionState.last_timeline.duplicate(true)
	_frame_index = 0
	_playback_accumulator = 0.0
	_is_playing = not _timeline.is_empty()
	if _is_playing:
		set_process(true)
	else:
		AppRouter.goto_result()


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
		AppRouter.goto_result()


func play_battle(setup: Dictionary) -> void:
	var payload: Dictionary = RUNNER.new().run(setup)
	SessionState.last_timeline = payload.get("timeline", []).duplicate(true)
	SessionState.last_battle_result = payload.get("result", {}).duplicate(true)


func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = frame.get("entities", []).duplicate(true)
	sync_token_views(build_token_snapshot())


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
		if token == null:
			token = TOKEN_VIEW_SCENE.instantiate()
			token.size = token.custom_minimum_size
			_token_host.add_child(token)
			_token_views[entity_id] = token
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
