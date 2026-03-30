extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	_assert_true(not content.get_unit("hero_angel").is_empty(), "hero_angel should exist")
	_assert_true(not content.get_strategy("strat_void_echo").is_empty(), "strat_void_echo should exist")
	_assert_true(not content.get_event("evt_hunter_fiend_arrival").is_empty(), "evt_hunter_fiend_arrival should exist")
	_assert_true(not content.get_battle("battle_void_gate_alpha").is_empty(), "battle_void_gate_alpha should exist")
	content.free()
	_finish()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
