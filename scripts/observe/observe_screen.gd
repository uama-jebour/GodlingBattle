extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")

var _timeline: Array = []
var _frame_index := 0
var _current_tick := 0
var _current_entities: Array = []


func _ready() -> void:
	if SessionState.battle_setup.is_empty():
		return
	if SessionState.last_timeline.is_empty():
		play_battle(SessionState.battle_setup)
	_timeline = SessionState.last_timeline.duplicate(true)
	_frame_index = 0
	_play_timeline()


func play_battle(setup: Dictionary) -> void:
	var payload: Dictionary = RUNNER.new().run(setup)
	SessionState.last_timeline = payload.get("timeline", []).duplicate(true)
	SessionState.last_battle_result = payload.get("result", {}).duplicate(true)


func apply_timeline_frame(frame: Dictionary) -> void:
	_current_tick = int(frame.get("tick", 0))
	_current_entities = frame.get("entities", []).duplicate(true)


func build_token_snapshot() -> Array:
	var rows: Array = []
	for entity in _current_entities:
		rows.append({
			"entity_id": str(entity.get("entity_id", "")),
			"display_name": str(entity.get("display_name", "")),
			"side": str(entity.get("side", "")),
			"hp_ratio": _hp_ratio(entity)
		})
	return rows


func _play_timeline() -> void:
	while _frame_index < _timeline.size():
		var frame = _timeline[_frame_index]
		apply_timeline_frame(frame)
		_frame_index += 1
	AppRouter.goto_result()


func _hp_ratio(entity: Dictionary) -> float:
	var hp := float(entity.get("hp", 0.0))
	var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
	return clampf(hp / max_hp, 0.0, 1.0)
