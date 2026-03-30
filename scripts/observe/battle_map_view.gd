extends Control

var _snapshot: Array = []


func set_snapshot(snapshot: Array) -> void:
	_snapshot = snapshot.duplicate(true)
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		rect.size = custom_minimum_size
	draw_rect(rect, Color("#101720"), true)

	var inset := Rect2(Vector2(96, 96), rect.size - Vector2(192, 192))
	if inset.size.x > 0.0 and inset.size.y > 0.0:
		draw_rect(inset, Color("#18232F"), false, 2.0)

	for row in _snapshot:
		var pos: Variant = row.get("position", Vector2.ZERO)
		if pos is not Vector2:
			continue
		var side := str(row.get("side", ""))
		var color := Color("#4EA3FF")
		if side == "enemy":
			color = Color("#E85F5F")
		elif side == "hero":
			color = Color("#E6C95E")
		draw_circle(pos, 3.0, color)
