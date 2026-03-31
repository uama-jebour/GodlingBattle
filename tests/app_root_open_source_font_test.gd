extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app_root_script := load("res://scripts/app_root.gd")
	if app_root_script == null:
		_failures.append("missing app_root.gd")
		_finish()
		return
	var app_root: Control = app_root_script.new()
	if app_root == null:
		_failures.append("failed to instantiate app_root")
		_finish()
		return

	if OS.get_name() == "macOS":
		if not app_root.has_method("_build_macos_font_theme"):
			_failures.append("missing _build_macos_font_theme")
		else:
			var theme_value: Variant = app_root.call("_build_macos_font_theme")
			if theme_value == null:
				_failures.append("expected macOS font theme")
			elif theme_value is Theme:
				var theme_instance: Theme = theme_value as Theme
				if theme_instance.default_font == null:
					_failures.append("expected default font in macOS theme")
				elif theme_instance.default_font is SystemFont:
					_failures.append("expected open-source bundled font on macOS, got SystemFont fallback")
				elif theme_instance.default_font is FontVariation:
					var font_variation := theme_instance.default_font as FontVariation
					var settings: Dictionary = font_variation.variation_opentype
					var weight := int(settings.get("wght", 0))
					if weight > 0 and weight < 900:
						_failures.append("expected heavier font weight >= 900 for readability, got %d" % weight)
					var embolden := float(font_variation.variation_embolden)
					if embolden < 0.25 or embolden > 0.5:
						_failures.append("expected thinner embolden in [0.25, 0.5], got %f" % embolden)
			else:
				_failures.append("expected Theme return type from _build_macos_font_theme")

	app_root.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
