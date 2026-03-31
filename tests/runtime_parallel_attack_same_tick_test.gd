extends SceneTree

const COMBAT := preload("res://scripts/battle_runtime/battle_combat_system.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var combat: RefCounted = COMBAT.new()
	var state := {
		"tick_rate": 10,
		"elapsed_ticks": 0,
		"entities": [
			{
				"entity_id": "ally_0",
				"side": "ally",
				"alive": true,
				"hp": 100.0,
				"max_hp": 100.0,
				"attack_power": 0.0,
				"attack_speed": 1.0,
				"attack_range": 1.0,
				"position": Vector2(0.0, 0.0),
				"attack_cooldown_ticks": 0
			},
			{
				"entity_id": "enemy_0",
				"side": "enemy",
				"alive": true,
				"hp": 50.0,
				"max_hp": 50.0,
				"attack_power": 7.0,
				"attack_speed": 1.0,
				"attack_range": 120.0,
				"position": Vector2(80.0, -10.0),
				"attack_cooldown_ticks": 0
			},
			{
				"entity_id": "enemy_1",
				"side": "enemy",
				"alive": true,
				"hp": 50.0,
				"max_hp": 50.0,
				"attack_power": 8.0,
				"attack_speed": 1.0,
				"attack_range": 120.0,
				"position": Vector2(80.0, 10.0),
				"attack_cooldown_ticks": 0
			}
		],
		"strategies": [],
		"log_entries": [],
		"casualties": [],
		"completed": false
	}

	combat.tick(state)
	var entities: Array = state.get("entities", [])
	var ally := entities[0] as Dictionary
	var hp_now := float(ally.get("hp", 0.0))
	var cooldown_a := int((entities[1] as Dictionary).get("attack_cooldown_ticks", 0))
	var cooldown_b := int((entities[2] as Dictionary).get("attack_cooldown_ticks", 0))

	if not is_equal_approx(hp_now, 85.0):
		_failures.append("expected ally hp to drop by both attacks in same tick to 85, got %f" % hp_now)
	if cooldown_a <= 0 or cooldown_b <= 0:
		_failures.append("expected both enemies to enter cooldown after attacking in same tick")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
