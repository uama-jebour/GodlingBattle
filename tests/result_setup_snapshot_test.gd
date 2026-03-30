extends SceneTree

const RESULT_SCENE := preload("res://scenes/result/result_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return

	session_state.battle_setup = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	}
	session_state.last_battle_result = {
		"victory": true,
		"survivors": ["hero_angel"],
		"casualties": [],
		"triggered_events": [],
		"triggered_strategies": []
	}

	var screen: Control = RESULT_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var snapshot_label := screen.get_node_or_null("Layout/SetupSnapshotLabel") as Label
	if snapshot_label == null:
		_failures.append("missing SetupSnapshotLabel")
		screen.queue_free()
		await process_frame
		_finish()
		return

	var text := String(snapshot_label.text)
	if text.find("英雄：") == -1:
		_failures.append("expected chinese hero label in setup snapshot")
	if text.find("友军：") == -1:
		_failures.append("expected chinese ally label in setup snapshot")
	if text.find("战技：") == -1:
		_failures.append("expected chinese strategy label in setup snapshot")
	if text.find("关卡：") == -1:
		_failures.append("expected chinese battle label in setup snapshot")
	if text.find("英雄：天使") == -1:
		_failures.append("expected localized hero name in setup snapshot")
	if text.find("野犬残形") == -1:
		_failures.append("expected localized ally name in setup snapshot")
	if text.find("核击协议") == -1:
		_failures.append("expected localized strategy name in setup snapshot")
	if text.find("虚无裂隙·二层") == -1:
		_failures.append("expected localized battle name in setup snapshot")
	if text.find("hero_id") != -1 or text.find("ally_ids") != -1 or text.find("strategy_ids") != -1 or text.find("battle_id") != -1:
		_failures.append("setup snapshot should not expose english field keys")
	if text.find("hero_angel") != -1 or text.find("strat_") != -1 or text.find("battle_void_") != -1:
		_failures.append("setup snapshot should not expose english ids")
	if text.find("20260330") == -1:
		_failures.append("expected seed in setup snapshot")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
