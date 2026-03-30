extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card_script := load("res://scripts/observe/strategy_card_view.gd")
	if card_script == null:
		_failures.append("missing strategy_card_view.gd")
		_finish(null)
		return

	var card = card_script.new()
	if card == null:
		_failures.append("failed to instantiate strategy card")
		_finish(null)
		return
	if not card.has_method("apply_state"):
		_failures.append("missing apply_state")
		_finish(card)
		return

	card.call("apply_state", {
		"name": "寒潮冲击",
		"cooldown_ratio": 0.50,
		"cooldown_remaining_seconds": 4.0,
		"cooldown_total_seconds": 8.0,
		"triggered": true
	})

	if not bool(card.get("is_triggered")):
		_failures.append("card should be triggered")
	if absf(float(card.get("cooldown_ratio")) - 0.5) > 0.001:
		_failures.append("cooldown_ratio should be 0.5")

	_finish(card)


func _finish(card) -> void:
	if card != null and is_instance_valid(card):
		card.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
