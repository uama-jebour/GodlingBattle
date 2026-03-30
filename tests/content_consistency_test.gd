extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	for pack in content.get_test_packs():
		for strategy_id in pack.get("strategy_ids", []):
			if content.get_strategy(str(strategy_id)).is_empty():
				_failures.append("missing strategy: %s" % strategy_id)
	content.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
