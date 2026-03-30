extends SceneTree

const EXPORTER := preload("res://tools/export_runtime_benchmark.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter: RefCounted = EXPORTER.new()
	var options: Dictionary = exporter.parse_user_args(OS.get_cmdline_user_args())
	var result: Dictionary = exporter.run_with_options(options)
	print("benchmark csv exported to %s" % str(result.get("output_csv_path", "")))
	print("benchmark summary exported to %s" % str(result.get("output_summary_json_path", "")))
	print("benchmark baseline path %s" % str(result.get("baseline_json_path", "")))
	for issue in result.get("issues", []):
		printerr(issue)
	quit(int(result.get("exit_code", 1)))
