extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _sum_alive_hp(entities: Array, enemy_side: bool) -> float:
	var total := 0.0
	for entity in entities:
		if not bool(entity.get("alive", false)):
			continue
		var side := str(entity.get("side", ""))
		if enemy_side and side != "enemy":
			continue
		if not enemy_side and side == "enemy":
			continue
		total += float(entity.get("hp", 0.0))
	return total


func _run() -> void:
	var payload: Dictionary = RUNNER.new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.size() < 3:
		_failures.append("timeline should have enough frames for pacing check")
		_finish()
		return

	var ally_damaged_early := false
	var enemy_damaged_early := false
	var max_tick := mini(40, timeline.size() - 1)
	for index in range(1, max_tick + 1):
		var prev_entities: Array = (timeline[index - 1] as Dictionary).get("entities", [])
		var now_entities: Array = (timeline[index] as Dictionary).get("entities", [])
		var ally_loss := _sum_alive_hp(prev_entities, false) - _sum_alive_hp(now_entities, false)
		var enemy_loss := _sum_alive_hp(prev_entities, true) - _sum_alive_hp(now_entities, true)
		if ally_loss > 0.01:
			ally_damaged_early = true
		if enemy_loss > 0.01:
			enemy_damaged_early = true

	if not ally_damaged_early:
		_failures.append("ally side should receive real damage within first 40 ticks")
	if not enemy_damaged_early:
		_failures.append("enemy side should receive real damage within first 40 ticks")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
