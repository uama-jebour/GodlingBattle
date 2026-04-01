class_name StoryEditor
extends VBoxContainer

signal lines_changed(lines: Array[String])

var _line_editors: Array[LineEdit] = []
var _lines: Array[String] = []

@onready var lines_container: VBoxContainer = $LinesContainer
@onready var add_line_button: Button = $AddLineButton


func _ready() -> void:
	if add_line_button:
		add_line_button.pressed.connect(_on_add_line_pressed)
	# Rebuild UI with any lines set before _ready
	if _lines.size() > 0:
		_rebuild_ui()


func set_lines(lines: Array[String]) -> void:
	_lines = lines.duplicate()
	if is_inside_tree():
		_rebuild_ui()


func get_lines() -> Array[String]:
	# If UI is built, get from editors; otherwise return stored lines
	if _line_editors.size() > 0 and is_inside_tree():
		var result: Array[String] = []
		for edit in _line_editors:
			result.append(edit.text)
		return result
	return _lines.duplicate()


func _rebuild_ui() -> void:
	if lines_container == null:
		return

	for child in lines_container.get_children():
		child.queue_free()
	_line_editors.clear()

	for i in range(_lines.size()):
		_add_line_editor(_lines[i])


func _add_line_editor(text: String) -> void:
	if lines_container == null:
		return

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_num := Label.new()
	line_num.text = "%d." % (_line_editors.size() + 1)
	line_num.custom_minimum_size.x = 30

	var edit := LineEdit.new()
	edit.text = text
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(_on_line_text_changed.bind(edit))

	var up_btn := Button.new()
	up_btn.text = "↑"
	up_btn.custom_minimum_size.x = 30
	up_btn.pressed.connect(_move_line_up.bind(edit))

	var down_btn := Button.new()
	down_btn.text = "↓"
	down_btn.custom_minimum_size.x = 30
	down_btn.pressed.connect(_move_line_down.bind(edit))

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_delete_line.bind(edit, hbox))

	hbox.add_child(line_num)
	hbox.add_child(edit)
	hbox.add_child(up_btn)
	hbox.add_child(down_btn)
	hbox.add_child(del_btn)

	lines_container.add_child(hbox)
	_line_editors.append(edit)


func _on_add_line_pressed() -> void:
	_add_line_editor("")
	_emit_changed()


func _on_line_text_changed(_new_text: String, _edit: LineEdit) -> void:
	_emit_changed()


func _move_line_up(edit: LineEdit) -> void:
	var index := _line_editors.find(edit)
	if index <= 0:
		return

	var hbox := edit.get_parent() as HBoxContainer
	if hbox == null:
		return

	lines_container.move_child(hbox, index - 1)
	_line_editors[index] = _line_editors[index - 1]
	_line_editors[index - 1] = edit
	_refresh_line_numbers()
	_emit_changed()


func _move_line_down(edit: LineEdit) -> void:
	var index := _line_editors.find(edit)
	if index < 0 or index >= _line_editors.size() - 1:
		return

	var hbox := edit.get_parent() as HBoxContainer
	if hbox == null:
		return

	lines_container.move_child(hbox, index + 1)
	_line_editors[index] = _line_editors[index + 1]
	_line_editors[index + 1] = edit
	_refresh_line_numbers()
	_emit_changed()


func _delete_line(edit: LineEdit, hbox: HBoxContainer) -> void:
	var index := _line_editors.find(edit)
	if index >= 0:
		_line_editors.remove_at(index)
	hbox.queue_free()
	_refresh_line_numbers()
	_emit_changed()


func _refresh_line_numbers() -> void:
	for i in range(_line_editors.size()):
		var edit := _line_editors[i]
		var hbox := edit.get_parent() as HBoxContainer
		if hbox and hbox.get_child_count() > 0:
			var label := hbox.get_child(0) as Label
			if label:
				label.text = "%d." % (i + 1)


func _emit_changed() -> void:
	lines_changed.emit(get_lines())
