extends Control

const MAC_OPEN_SOURCE_FONT_PATH := "res://assets/fonts/SmileySans-Oblique.ttf"
const MAC_UI_FONT_SIZE := 22
const MAC_UI_FONT_WEIGHT := 900
const MAC_UI_FONT_EMBOLDEN := 0.35

@onready var screen_host := Control.new()


func _ready() -> void:
	_apply_platform_ui_theme()
	screen_host.name = "ScreenHost"
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_host)
	var app_router := get_node_or_null("/root/AppRouter")
	if app_router == null:
		return
	app_router.bind_host(screen_host)
	app_router.goto_preparation()


func _apply_platform_ui_theme() -> void:
	if OS.get_name() != "macOS":
		return
	theme = _build_macos_font_theme()


func _build_macos_font_theme() -> Theme:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray([
		"PingFang SC",
		"Hiragino Sans GB",
		"Heiti SC",
		"Helvetica Neue"
	])
	var theme_override := Theme.new()
	var open_source_font := _load_open_source_font_for_macos()
	if open_source_font != null:
		theme_override.default_font = open_source_font
	else:
		theme_override.default_font = system_font
	theme_override.default_font_size = MAC_UI_FONT_SIZE
	return theme_override


func _load_open_source_font_for_macos() -> Font:
	if not FileAccess.file_exists(MAC_OPEN_SOURCE_FONT_PATH):
		return null
	var font_bytes := FileAccess.get_file_as_bytes(MAC_OPEN_SOURCE_FONT_PATH)
	if font_bytes.is_empty():
		return null
	var font_file := FontFile.new()
	font_file.data = font_bytes
	var font_variation := FontVariation.new()
	font_variation.base_font = font_file
	font_variation.variation_opentype = {"wght": MAC_UI_FONT_WEIGHT}
	font_variation.variation_embolden = MAC_UI_FONT_EMBOLDEN
	return font_variation
