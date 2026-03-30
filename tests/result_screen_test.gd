extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/result/result_screen.gd").new()
	var summary: Dictionary = screen.build_summary({
		"victory": true,
		"survivors": ["hero_1"],
		"log_entries": [{"type": "event_warning", "event_id": "evt_hunter_fiend_arrival"}]
	})
	assert(summary.has("headline"))
	assert(summary.has("survivor_lines"))
	assert(summary.has("event_lines"))
	screen.free()
	quit(0)
