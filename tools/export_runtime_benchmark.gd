extends RefCounted

const BENCHMARK := preload("res://tools/runtime_benchmark.gd")
const DEFAULT_OUTPUT_CSV_PATH := "user://artifacts/benchmarks/runtime_benchmark_latest.csv"
const DEFAULT_BASELINE_ROOT_PATH := "res://data/benchmarks"
const DEFAULT_BASELINE_PROFILE := "main"


func default_scenarios() -> Array:
	return [
		{
			"scenario_id": "alpha_stack",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave", "strat_nuclear_strike"],
				"battle_id": "battle_void_gate_alpha",
				"seed": 20260330
			},
			"iterations": 6,
			"expect_deterministic": true
		},
		{
			"scenario_id": "beta_multi_event",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave", "strat_counter_demon_summon", "strat_nuclear_strike"],
				"battle_id": "battle_void_gate_beta",
				"seed": 20260330
			},
			"iterations": 6,
			"expect_deterministic": true
		}
	]


func parse_user_args(args: Array) -> Dictionary:
	var options := {}
	for raw_arg in args:
		var arg := str(raw_arg)
		if arg.begins_with("--output="):
			options["output_csv_path"] = arg.trim_prefix("--output=")
		elif arg.begins_with("--summary-json="):
			options["output_summary_json_path"] = arg.trim_prefix("--summary-json=")
		elif arg.begins_with("--baseline="):
			options["baseline_json_path"] = arg.trim_prefix("--baseline=")
		elif arg.begins_with("--baseline-profile="):
			options["baseline_profile"] = arg.trim_prefix("--baseline-profile=")
		elif arg.begins_with("--baseline-root="):
			options["baseline_root_path"] = arg.trim_prefix("--baseline-root=")
		elif arg.begins_with("--max-ms="):
			options["max_ms_threshold"] = float(arg.trim_prefix("--max-ms="))
		elif arg.begins_with("--ratio="):
			options["ratio_threshold"] = float(arg.trim_prefix("--ratio="))
		elif arg == "--write-baseline":
			options["write_baseline"] = true
		elif arg == "--require-baseline":
			options["require_baseline"] = true
	return options


func run_with_options(options: Dictionary) -> Dictionary:
	var scenarios: Array = options.get("scenarios", []).duplicate(true)
	if scenarios.is_empty():
		scenarios = default_scenarios()
	var output_csv_path := str(options.get("output_csv_path", DEFAULT_OUTPUT_CSV_PATH))
	var output_summary_json_path := str(options.get(
		"output_summary_json_path",
		"%s.json" % output_csv_path.get_basename()
	))
	var max_ms_threshold := float(options.get("max_ms_threshold", 250.0))
	var ratio_threshold := float(options.get("ratio_threshold", 1.2))
	var write_baseline := bool(options.get("write_baseline", false))
	var require_baseline := bool(options.get("require_baseline", false))
	var baseline_profile := str(options.get("baseline_profile", DEFAULT_BASELINE_PROFILE))
	var baseline_root_path := str(options.get("baseline_root_path", DEFAULT_BASELINE_ROOT_PATH))
	var baseline_json_path := str(options.get(
		"baseline_json_path",
		resolve_baseline_path(baseline_profile, baseline_root_path)
	))

	var baseline_summary: Dictionary = options.get("baseline_summary", {}).duplicate(true)
	if baseline_summary.is_empty():
		baseline_summary = _read_summary_json(baseline_json_path)
	if require_baseline and baseline_summary.is_empty() and not write_baseline:
		baseline_summary = {}

	var benchmark := BENCHMARK.new()
	var summary: Dictionary = benchmark.run_scenarios(
		scenarios,
		max_ms_threshold,
		{} if write_baseline else baseline_summary,
		ratio_threshold
	)
	var issues: Array = summary.get("issues", []).duplicate()
	if require_baseline and baseline_summary.is_empty() and not write_baseline:
		issues.append("required baseline missing: %s" % baseline_json_path)

	var csv_text: String = str(benchmark.call("build_summary_csv", summary))
	if not _write_text_file(output_csv_path, csv_text):
		issues.append("failed writing csv: %s" % output_csv_path)
	if not _write_text_file(output_summary_json_path, JSON.stringify(summary, "\t")):
		issues.append("failed writing summary json: %s" % output_summary_json_path)
	if write_baseline and not _write_text_file(baseline_json_path, JSON.stringify(summary, "\t")):
		issues.append("failed writing baseline json: %s" % baseline_json_path)

	summary["issues"] = issues
	return {
		"exit_code": 0 if issues.is_empty() else 1,
		"output_csv_path": output_csv_path,
		"output_summary_json_path": output_summary_json_path,
		"baseline_json_path": baseline_json_path,
		"issues": issues,
		"summary": summary
	}


func resolve_baseline_path(profile: String, baseline_root_path: String = DEFAULT_BASELINE_ROOT_PATH) -> String:
	var profile_name := profile
	if profile_name.is_empty():
		profile_name = DEFAULT_BASELINE_PROFILE
	return "%s/runtime_benchmark_baseline_%s.json" % [baseline_root_path, profile_name]


func _read_summary_json(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return {}
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _write_text_file(path: String, content: String) -> bool:
	if path.is_empty():
		return false
	var absolute_path := ProjectSettings.globalize_path(path)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if mkdir_error != OK:
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	file.close()
	return true
