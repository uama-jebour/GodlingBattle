extends Control

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")


func _ready() -> void:
	if SessionState.battle_setup.is_empty():
		return
	play_battle(SessionState.battle_setup)


func play_battle(setup: Dictionary) -> void:
	var payload: Dictionary = RUNNER.new().run(setup)
	SessionState.last_timeline = payload.get("timeline", []).duplicate(true)
	SessionState.last_battle_result = payload.get("result", {}).duplicate(true)
	AppRouter.goto_result()
