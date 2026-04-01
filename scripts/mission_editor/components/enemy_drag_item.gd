class_name EnemyDragItem
extends HBoxContainer

var unit_id: String = ""
var display_name: String = ""

@onready var name_label: Label = $NameLabel
@onready var drag_button: Button = $DragButton


func _ready() -> void:
	if drag_button:
		drag_button.gui_input.connect(_on_drag_input)


func setup(p_unit_id: String, p_display_name: String) -> void:
	unit_id = p_unit_id
	display_name = p_display_name
	if name_label:
		name_label.text = p_display_name


func _on_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Trigger drag forwarding
		_get_drag_data(Vector2.ZERO)


func _get_drag_data(at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = display_name
	preview.add_theme_color_override("font_color", Color.WHITE)
	preview.add_theme_stylebox_override("normal", _create_preview_style())
	drag_button.set_drag_preview(preview)
	return {"unit_id": unit_id, "display_name": display_name}


func _create_preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.6, 0.9)
	style.border_color = Color(0.4, 0.4, 0.8)
	style.set_border_width_all(2)
	style.set_content_margin_all(4)
	return style
