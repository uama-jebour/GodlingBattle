extends PanelContainer

@export var slot_title := ""
@export var value_text := ""


func render(title: String, value: String) -> void:
	slot_title = title
	value_text = value
