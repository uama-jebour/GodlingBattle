class_name PlacedEnemyIcon
extends Control

signal delete_requested(icon: PlacedEnemyIcon)

var unit_id: String = ""
var spawn_anchor: String = ""

@onready var icon_label: Label = $IconLabel
@onready var delete_btn: Button = $DeleteButton


func _ready() -> void:
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_pressed)


func setup(p_unit_id: String, p_spawn_anchor: String, display_name: String) -> void:
	unit_id = p_unit_id
	spawn_anchor = p_spawn_anchor
	if icon_label:
		icon_label.text = display_name


func _on_delete_pressed() -> void:
	delete_requested.emit(self)
