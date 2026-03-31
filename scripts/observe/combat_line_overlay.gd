extends Control

const ARC_SEGMENTS := 18
const ARC_CURVE_MIN := 24.0
const ARC_CURVE_MAX := 92.0
const SWEEP_BUILD_RATIO := 0.5

var _lines: Array = []


func set_lines(lines: Array) -> void:
	_lines = lines.duplicate(true)
	queue_redraw()


func line_count() -> int:
	return _lines.size()


func line_count_by_kind(kind: String) -> int:
	var count := 0
	for row in _lines:
		if str((row as Dictionary).get("kind", "")) == kind:
			count += 1
	return count


func _ready() -> void:
	set_process(true)


func _draw() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	var curved_lines := _prepare_curved_lines(_lines)
	for row in curved_lines:
		var line := row as Dictionary
		var kind := str(line.get("kind", ""))
		var from: Vector2 = line.get("from", Vector2.ZERO)
		var to: Vector2 = line.get("to", Vector2.ZERO)
		if from.distance_to(to) <= 1.0:
			continue
		var control: Vector2 = line.get("control", (from + to) * 0.5)
		var color: Color = line.get("color", Color(0.8, 0.8, 0.8, 0.7))
		var width := maxf(float(line.get("width", 2.0)), 1.0)
		var life_t := float(line.get("life_t", -1.0))
		var sweep := Vector2.ZERO
		if life_t >= 0.0:
			sweep = _sweep_window(life_t)
		else:
			var speed := maxf(float(line.get("pulse_speed", 1.1)), 0.2)
			var phase_offset := float(line.get("phase", 0.0))
			var loop_t := fposmod(now * speed + phase_offset, 1.0)
			sweep = _sweep_window(loop_t)
		if sweep.y <= sweep.x + 0.001:
			continue
		if kind == "event_response_indicator" and str(line.get("variant", "")) == "seal_x":
			_draw_seal_x_indicator(line, sweep, color, width)
			continue
		var segment := _quadratic_segment_points(from, control, to, sweep.x, sweep.y)
		if segment.size() <= 1:
			continue
		var glow := Color(color.r, color.g, color.b, color.a * 0.48)
		var hot_glow := Color(color.r, color.g, color.b, color.a * 0.22)
		draw_polyline(segment, glow, width + 8.0, true)
		draw_polyline(segment, hot_glow, width + 12.0, true)
		draw_polyline(segment, color, width + 0.6, true)

		var head_point := segment[segment.size() - 1]
		var prev_point := segment[maxi(segment.size() - 2, 0)]
		var direction := (head_point - prev_point).normalized()
		if direction.length_squared() <= 0.0001:
			direction = (to - control).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var head_base := head_point - direction * 23.0
		var head_color := Color(1.0, 1.0, 1.0, minf(1.0, color.a + 0.2))
		draw_colored_polygon(
			PackedVector2Array([head_point, head_base + normal * 10.0, head_base - normal * 10.0]),
			head_color
		)
		draw_polyline(PackedVector2Array([head_point, head_base + normal * 10.0, head_base - normal * 10.0, head_point]), color, 2.0, true)
		var origin_pulse_alpha := clampf(float(line.get("origin_pulse_alpha", 0.0)), 0.0, 1.0)
		if origin_pulse_alpha > 0.001:
			var pulse_core := Color(1.0, 1.0, 0.95, color.a * (0.28 + origin_pulse_alpha * 0.56))
			var pulse_shell := Color(color.r, color.g, color.b, color.a * (0.32 + origin_pulse_alpha * 0.62))
			var pulse_radius := 8.0 + origin_pulse_alpha * 8.0
			draw_circle(from, pulse_radius, pulse_core)
			draw_arc(from, pulse_radius + 4.0, 0.0, TAU, 28, pulse_shell, 2.0, true)
			draw_arc(from, pulse_radius + 10.0, 0.0, TAU, 28, pulse_shell, 1.4, true)


func _draw_seal_x_indicator(line: Dictionary, sweep: Vector2, color: Color, width: float) -> void:
	var from: Vector2 = line.get("from", Vector2.ZERO)
	var to: Vector2 = line.get("to", Vector2.ZERO)
	var center := (from + to) * 0.5
	var radius := maxf(from.distance_to(to) * 0.5, 20.0)
	var diag := radius * 0.75
	var p1 := center + Vector2(-diag, -diag)
	var p2 := center + Vector2(diag, diag)
	var p3 := center + Vector2(-diag, diag)
	var p4 := center + Vector2(diag, -diag)

	var glow := Color(color.r, color.g, color.b, color.a * 0.52)
	var hot := Color(1.0, 1.0, 1.0, minf(1.0, color.a * 0.92))
	_draw_segmented_line(p1, p2, sweep, glow, width + 6.0)
	_draw_segmented_line(p3, p4, sweep, glow, width + 6.0)
	_draw_segmented_line(p1, p2, sweep, color, width + 1.4)
	_draw_segmented_line(p3, p4, sweep, color, width + 1.4)
	_draw_segmented_line(p1, p2, sweep, hot, width * 0.5 + 0.6)
	_draw_segmented_line(p3, p4, sweep, hot, width * 0.5 + 0.6)

	var life_t := clampf(float(line.get("life_t", 0.0)), 0.0, 1.0)
	var ripple_t := 1.0 - life_t
	var ripple_radius := radius * (0.22 + ripple_t * 0.58)
	var ripple_alpha := color.a * (0.20 + ripple_t * 0.28)
	var ripple := Color(color.r, color.g, color.b, ripple_alpha)
	draw_arc(center, ripple_radius, 0.0, TAU, 28, ripple, width * 0.72 + 1.1, true)
	draw_arc(center, ripple_radius + 8.0, 0.0, TAU, 28, Color(ripple.r, ripple.g, ripple.b, ripple.a * 0.74), width * 0.48 + 0.9, true)


func _draw_segmented_line(start: Vector2, end: Vector2, sweep: Vector2, color: Color, width: float) -> void:
	var t0 := clampf(sweep.x, 0.0, 1.0)
	var t1 := clampf(sweep.y, 0.0, 1.0)
	if t1 <= t0 + 0.001:
		return
	var seg_start := start.lerp(end, t0)
	var seg_end := start.lerp(end, t1)
	draw_line(seg_start, seg_end, color, maxf(width, 1.0), true)


func _process(_delta: float) -> void:
	if not _lines.is_empty():
		queue_redraw()


func _prepare_curved_lines(lines: Array) -> Array:
	var key_to_total: Dictionary = {}
	var key_to_direction_count: Dictionary = {}
	for row in lines:
		var line := row as Dictionary
		var from: Vector2 = line.get("from", Vector2.ZERO)
		var to: Vector2 = line.get("to", Vector2.ZERO)
		if from.distance_to(to) <= 1.0:
			continue
		var pair_key := _pair_key(from, to)
		key_to_total[pair_key] = int(key_to_total.get(pair_key, 0)) + 1
	var prepared: Array = []
	for row in lines:
		var line := row as Dictionary
		var from: Vector2 = line.get("from", Vector2.ZERO)
		var to: Vector2 = line.get("to", Vector2.ZERO)
		if from.distance_to(to) <= 1.0:
			continue
		var pair_key := _pair_key(from, to)
		var direction_key := _direction_key(from, to)
		var counter_key := "%s|%s" % [pair_key, direction_key]
		var direction_index := int(key_to_direction_count.get(counter_key, 0))
		key_to_direction_count[counter_key] = direction_index + 1
		var total_on_pair := int(key_to_total.get(pair_key, 1))
		var curve_sign := _curve_sign(from, to)
		var lane_offset := float(direction_index) * 0.45
		curve_sign += curve_sign * lane_offset
		if total_on_pair == 1:
			curve_sign *= 0.85
		var control := _curve_control_point(from, to, curve_sign)
		var merged := line.duplicate(true)
		merged["control"] = control
		prepared.append(merged)
	return prepared


func _pair_key(from: Vector2, to: Vector2) -> String:
	var a := _point_key(from)
	var b := _point_key(to)
	if a <= b:
		return "%s<->%s" % [a, b]
	return "%s<->%s" % [b, a]


func _direction_key(from: Vector2, to: Vector2) -> String:
	return "%s->%s" % [_point_key(from), _point_key(to)]


func _point_key(point: Vector2) -> String:
	return "%d,%d" % [int(round(point.x)), int(round(point.y))]


func _curve_sign(from: Vector2, to: Vector2) -> float:
	var a := _point_key(from)
	var b := _point_key(to)
	return 1.0 if a <= b else -1.0


func _curve_control_point(from: Vector2, to: Vector2, curve_sign: float) -> Vector2:
	var mid := (from + to) * 0.5
	var distance := from.distance_to(to)
	var direction := (to - from).normalized()
	var a := _point_key(from)
	var b := _point_key(to)
	if a > b:
		direction = (from - to).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var curve_amount := clampf(distance * 0.12, ARC_CURVE_MIN, ARC_CURVE_MAX)
	return mid + normal * curve_amount * curve_sign


func _draw_quadratic_arc(from: Vector2, control: Vector2, to: Vector2, color: Color, width: float) -> void:
	var points: PackedVector2Array = []
	for i in range(ARC_SEGMENTS + 1):
		var t := float(i) / float(ARC_SEGMENTS)
		points.append(_quadratic_point(from, control, to, t))
	draw_polyline(points, color, width, true)


func _quadratic_segment_points(from: Vector2, control: Vector2, to: Vector2, t_start: float, t_end: float) -> PackedVector2Array:
	var start := clampf(t_start, 0.0, 1.0)
	var end := clampf(t_end, 0.0, 1.0)
	var points: PackedVector2Array = []
	if end <= start:
		return points
	for i in range(ARC_SEGMENTS + 1):
		var local_t := float(i) / float(ARC_SEGMENTS)
		var t := lerpf(start, end, local_t)
		points.append(_quadratic_point(from, control, to, t))
	return points


func _sweep_window(progress: float) -> Vector2:
	var t := clampf(progress, 0.0, 1.0)
	if t <= SWEEP_BUILD_RATIO:
		var end := t / SWEEP_BUILD_RATIO
		return Vector2(0.0, end)
	var fade_t := (t - SWEEP_BUILD_RATIO) / maxf(1.0 - SWEEP_BUILD_RATIO, 0.001)
	return Vector2(fade_t, 1.0)


func _quadratic_point(from: Vector2, control: Vector2, to: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * from + 2.0 * u * t * control + t * t * to
