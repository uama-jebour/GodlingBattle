extends SceneTree

const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var resolver = DISPLAY_NAME_RESOLVER.new()

	_assert_equal(resolver.unit_name_from_unit_id("hero_angel"), "英雄：天使", "hero unit id should resolve localized display name")

	var enemy_name := resolver.unit_name_from_entity_id("enemy_wandering_demon_4")
	_assert_true(enemy_name.find("enemy_") == -1, "enemy entity id should not expose english prefix")

	_assert_equal(resolver.strategy_name("strat_chill_wave"), "寒潮冲击", "strategy id should resolve localized name")
	_assert_equal(resolver.event_name("evt_hunter_fiend_arrival"), "追猎魔登场", "event id should resolve localized name")
	_assert_equal(resolver.battle_name("battle_void_gate_beta"), "虚无裂隙·二层", "battle id should resolve localized display name")

	_finish()


func _assert_equal(actual: String, expected: String, message: String) -> void:
	if actual == expected:
		return
	_failures.append("%s (expected: %s, actual: %s)" % [message, expected, actual])


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
