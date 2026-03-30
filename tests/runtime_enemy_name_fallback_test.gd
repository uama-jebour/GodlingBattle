extends SceneTree

const BATTLE_STATE := preload("res://scripts/battle_runtime/battle_state.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := BATTLE_STATE.new()
	if not state.has_method("_fallback_enemy_def"):
		_failures.append("missing _fallback_enemy_def")
		_finish()
		return
	var enemy_def: Dictionary = state.call("_fallback_enemy_def", "enemy_missing_test")
	if str(enemy_def.get("display_name", "")) == "敌方单位":
		_failures.append("fallback enemy display_name should not be generic 敌方单位")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
