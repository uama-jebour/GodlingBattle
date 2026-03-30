extends SceneTree

const STRATEGY_CARD_SCENE := preload("res://scenes/observe/strategy_card_view.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var card := STRATEGY_CARD_SCENE.instantiate()
	root.add_child(card)
	await process_frame

	var name_label := card.get_node_or_null("NameLabel") as Label
	var cooldown_label := card.get_node_or_null("CooldownLabel") as Label
	var cooldown_fill := card.get_node_or_null("CooldownFill") as ColorRect

	if name_label == null:
		_failures.append("missing NameLabel")
	if cooldown_label == null:
		_failures.append("missing CooldownLabel")
	if cooldown_fill == null:
		_failures.append("missing CooldownFill")

	if _failures.is_empty():
		card.call("apply_state", {
			"name": "核击协议",
			"cooldown_ratio": 0.25,
			"cooldown_remaining_seconds": 18.0,
			"cooldown_total_seconds": 24.0,
			"triggered": false
		})
		if name_label.text != "核击协议":
			_failures.append("expected NameLabel text updated")
		if cooldown_label.text.find("18.0s / 24.0s") == -1:
			_failures.append("expected CooldownLabel text updated")
		if absf(cooldown_fill.anchor_top - 0.75) > 0.001:
			_failures.append("expected CooldownFill anchor_top updated")

	card.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
