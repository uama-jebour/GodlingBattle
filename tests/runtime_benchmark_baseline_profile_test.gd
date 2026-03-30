extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter_script: GDScript = load("res://tools/export_runtime_benchmark.gd")
	if exporter_script == null:
		_failures.append("missing export_runtime_benchmark.gd")
		_finish()
		return
	var exporter: Object = exporter_script.new()
	if not exporter.has_method("run_with_options"):
		_failures.append("missing run_with_options")
		_finish()
		return

	var parsed: Dictionary = exporter.call("parse_user_args", [
		"--baseline-profile=feature_a",
		"--write-baseline",
		"--require-baseline"
	])
	if str(parsed.get("baseline_profile", "")) != "feature_a":
		_failures.append("parse_user_args should parse baseline_profile")
	if not bool(parsed.get("write_baseline", false)):
		_failures.append("parse_user_args should parse write_baseline flag")
	if not bool(parsed.get("require_baseline", false)):
		_failures.append("parse_user_args should parse require_baseline flag")

	var profile := "ci_profile_test"
	var baseline_root := "user://benchmark_baselines"
	var baseline_path := _baseline_path(profile, baseline_root)
	_remove_file_if_exists(baseline_path)

	var scenarios := [
		{
			"scenario_id": "profile_alpha",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo"],
				"battle_id": "battle_void_gate_alpha",
				"seed": 20260330
			},
			"iterations": 1,
			"expect_deterministic": false
		}
	]

	var write_result: Dictionary = exporter.call("run_with_options", {
		"scenarios": scenarios,
		"baseline_profile": profile,
		"baseline_root_path": baseline_root,
		"write_baseline": true,
		"max_ms_threshold": 5000.0,
		"ratio_threshold": 10.0
	})
	if int(write_result.get("exit_code", -1)) != 0:
		_failures.append("write_baseline run should pass")
	if not FileAccess.file_exists(ProjectSettings.globalize_path(baseline_path)):
		_failures.append("write_baseline should create baseline file")

	var gate_result: Dictionary = exporter.call("run_with_options", {
		"scenarios": scenarios,
		"baseline_profile": profile,
		"baseline_root_path": baseline_root,
		"require_baseline": true,
		"max_ms_threshold": 5000.0,
		"ratio_threshold": 10.0
	})
	if int(gate_result.get("exit_code", -1)) != 0:
		_failures.append("existing baseline gate should pass")

	_remove_file_if_exists(baseline_path)
	var missing_baseline_result: Dictionary = exporter.call("run_with_options", {
		"scenarios": scenarios,
		"baseline_profile": profile,
		"baseline_root_path": baseline_root,
		"require_baseline": true,
		"max_ms_threshold": 5000.0,
		"ratio_threshold": 10.0
	})
	if int(missing_baseline_result.get("exit_code", 0)) != 1:
		_failures.append("missing required baseline should fail")

	_finish()


func _baseline_path(profile: String, baseline_root: String) -> String:
	return "%s/runtime_benchmark_baseline_%s.json" % [baseline_root, profile]


func _remove_file_if_exists(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return
	DirAccess.remove_absolute(absolute)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
