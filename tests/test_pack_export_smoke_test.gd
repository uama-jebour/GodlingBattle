extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter: RefCounted = load("res://tools/export_test_packs.gd").new()
	var csv: String = exporter.build_csv([
		{"battle_id": "battle_void_gate_alpha", "victory": true, "elapsed_seconds": 12.0}
	])
	assert("battle_id" in csv)
	assert("battle_void_gate_alpha" in csv)
	quit(0)
