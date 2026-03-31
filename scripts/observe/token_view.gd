extends Control

const COLOR_HERO := Color("#F2D66B")
const COLOR_ALLY := Color("#66C8FF")
const COLOR_ENEMY := Color("#FF6E6E")
const COLOR_HERO_FILL := Color("#6A5011")
const COLOR_ALLY_FILL := Color("#123A63")
const COLOR_ENEMY_FILL := Color("#5A1A22")
const COLOR_HP_BG := Color(0.17, 0.2, 0.24, 0.95)
const COLOR_HP_FILL := Color(0.42, 0.89, 0.52, 0.95)
const COLOR_HP_LOW := Color(0.92, 0.3, 0.24, 0.95)
const COLOR_HIT_FLASH := Color(1.0, 0.22, 0.22, 0.22)
const COLOR_EFFECT_RING := Color(0.55, 0.86, 1.0, 0.9)
const COLOR_DEAD_OVERLAY := Color(0.02, 0.03, 0.04, 0.38)
const COLOR_DEATH_MARKER := Color(1.0, 0.82, 0.82, 1.0)
const COLOR_TEXT_MAIN := Color("#F7FAFF")
const COLOR_TEXT_SHADOW := Color(0.01, 0.02, 0.03, 0.72)
const COLOR_DAMAGE_TEXT := Color(1.0, 0.91, 0.74, 1.0)
const COLOR_DAMAGE_SPARK := Color(1.0, 0.6, 0.45, 0.85)
const DAMAGE_POPUP_DURATION_TICKS := 8.0
const DAMAGE_POPUP_RISE_PX := 12.0
const DAMAGE_PARTICLE_COUNT := 6
const TITLE_BAR_HEIGHT := 26.0
const TITLE_TEXT_BASELINE := 20.0
const POSITION_SMOOTH_SPEED := 14.0
const POSITION_SMOOTH_MIN_ALPHA := 0.16
const POSITION_SNAP_DISTANCE := 2000.0
const HP_ARC_START_RAD := 2.45
const HP_ARC_SWEEP_RAD := 4.62
const HP_ARC_WIDTH := 4.0
const STRATEGY_HIGHLIGHT_RING_COLOR := Color(1.0, 0.92, 0.64, 0.95)
const STRATEGY_HIGHLIGHT_RING_OUTER_COLOR := Color(1.0, 0.78, 0.42, 0.92)

var entity_id := ""
var display_name := ""
var hp_ratio := 1.0
var side := ""
var world_position := Vector2.ZERO
var is_hit := false
var is_affected := false
var is_dead := false
var damage_value := 0
var show_death_marker_until_tick := -1
var _visual_tick := -1
var _damage_popup_tick := -1
var _damage_popup_value := 0
var _target_position := Vector2.ZERO
var _has_target_position := false
var strategy_highlight_alpha := 0.0


func apply_snapshot(snapshot: Dictionary) -> void:
	entity_id = str(snapshot.get("entity_id", ""))
	display_name = str(snapshot.get("display_name", ""))
	hp_ratio = clampf(float(snapshot.get("hp_ratio", 1.0)), 0.0, 1.0)
	side = str(snapshot.get("side", ""))
	world_position = _as_vector2(snapshot.get("position", Vector2.ZERO))
	var next_position := Vector2(round(world_position.x), round(world_position.y))
	if not _has_target_position:
		position = next_position
		_target_position = next_position
		_has_target_position = true
	else:
		if position.distance_to(next_position) > POSITION_SNAP_DISTANCE:
			position = next_position
		_target_position = next_position
		set_process(true)
	size = Vector2(round(custom_minimum_size.x), round(custom_minimum_size.y))
	queue_redraw()


func set_visual_flags(flags: Dictionary) -> void:
	is_hit = bool(flags.get("is_hit", false))
	is_affected = bool(flags.get("is_affected", false))
	is_dead = bool(flags.get("is_dead", false))
	damage_value = maxi(0, roundi(float(flags.get("damage_value", 0.0))))
	show_death_marker_until_tick = int(flags.get("show_death_marker_until_tick", -1))
	_visual_tick = int(flags.get("current_tick", _visual_tick))
	strategy_highlight_alpha = clampf(float(flags.get("strategy_highlight_alpha", 0.0)), 0.0, 1.0)
	if damage_value > 0:
		_damage_popup_value = damage_value
		_damage_popup_tick = _visual_tick
	queue_redraw()


func _process(delta: float) -> void:
	if not _has_target_position:
		set_process(false)
		return
	var current := position
	var alpha := maxf(POSITION_SMOOTH_MIN_ALPHA, clampf(delta * POSITION_SMOOTH_SPEED, 0.0, 1.0))
	var next := current.lerp(_target_position, alpha)
	if next.distance_to(_target_position) <= 0.5:
		next = _target_position
	next = Vector2(round(next.x), round(next.y))
	if next != current:
		position = next
		queue_redraw()
	if position == _target_position:
		set_process(false)


func is_death_marker_visible(current_tick: int) -> bool:
	return is_dead and show_death_marker_until_tick >= 0 and current_tick <= show_death_marker_until_tick


func _as_vector2(raw_value) -> Vector2:
	if raw_value is Vector2:
		return raw_value
	return Vector2.ZERO


func get_side_color() -> Color:
	if side == "hero":
		return COLOR_HERO
	if side == "enemy":
		return COLOR_ENEMY
	return COLOR_ALLY


func get_hp_fill_color() -> Color:
	if hp_ratio <= 0.3:
		return COLOR_HP_LOW
	return COLOR_HP_FILL


func get_fill_color() -> Color:
	if side == "hero":
		return COLOR_HERO_FILL
	if side == "enemy":
		return COLOR_ENEMY_FILL
	return COLOR_ALLY_FILL


func get_title_bar_color() -> Color:
	if side == "hero":
		return Color("#2F2508")
	if side == "enemy":
		return Color("#2B0B10")
	return Color("#081D34")


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		rect = Rect2(Vector2.ZERO, custom_minimum_size)
	var circle_center := _token_circle_center(rect)
	var circle_radius := _token_circle_radius(rect)
	_draw_token_surface(rect)
	if is_dead:
		draw_circle(circle_center, circle_radius, COLOR_DEAD_OVERLAY)
	if is_hit:
		draw_circle(circle_center, circle_radius, COLOR_HIT_FLASH)
	if is_affected:
		draw_arc(circle_center, circle_radius + 8.0, 0.0, TAU, 32, COLOR_EFFECT_RING, 2.0)
	if strategy_highlight_alpha > 0.001:
		var phase := float(Time.get_ticks_msec() % 280) / 280.0
		var flicker := 0.72 + 0.28 * sin(phase * TAU)
		var inner_color := STRATEGY_HIGHLIGHT_RING_COLOR
		inner_color.a *= strategy_highlight_alpha * flicker
		var outer_color := STRATEGY_HIGHLIGHT_RING_OUTER_COLOR
		outer_color.a *= strategy_highlight_alpha * (0.58 + flicker * 0.22)
		var ring_radius := circle_radius + 12.0 + (1.0 - strategy_highlight_alpha) * 6.0
		draw_arc(circle_center, ring_radius, 0.0, TAU, 56, inner_color, 3.2, true)
		draw_arc(circle_center, ring_radius + 5.0, 0.0, TAU, 56, outer_color, 2.2, true)

	var hp_radius := circle_radius + 6.0
	draw_arc(
		circle_center,
		hp_radius,
		HP_ARC_START_RAD,
		HP_ARC_START_RAD + HP_ARC_SWEEP_RAD,
		56,
		COLOR_HP_BG,
		HP_ARC_WIDTH,
		true
	)
	draw_arc(
		circle_center,
		hp_radius,
		HP_ARC_START_RAD,
		HP_ARC_START_RAD + HP_ARC_SWEEP_RAD * hp_ratio,
		56,
		get_hp_fill_color(),
		HP_ARC_WIDTH,
		true
	)

	var title := display_name if not display_name.is_empty() else entity_id
	var label_font := _label_font()
	_draw_text_with_shadow(label_font, Vector2(6, TITLE_TEXT_BASELINE), title, rect.size.x - 12, 20, COLOR_TEXT_MAIN)
	if _is_damage_popup_visible():
		_draw_damage_particles(rect)
		_draw_damage_popup(rect, label_font)
	if is_death_marker_visible(_visual_tick):
		_draw_text_with_shadow(label_font, Vector2(6, rect.size.y - 8.0), "已阵亡", rect.size.x - 12, 18, COLOR_DEATH_MARKER)


func _label_font() -> Font:
	var font := get_theme_default_font()
	if font != null:
		return font
	return ThemeDB.fallback_font


func _draw_token_surface(rect: Rect2) -> void:
	var center := _token_circle_center(rect)
	var radius := _token_circle_radius(rect)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.24)
	draw_circle(center + Vector2(0.0, 2.0), radius + 1.0, shadow_color)
	draw_circle(center, radius, get_fill_color())
	draw_circle(center + Vector2(-5.0, -6.0), radius * 0.56, Color(1.0, 1.0, 1.0, 0.12))
	draw_circle(center + Vector2(4.0, 6.0), radius * 0.72, Color(0.0, 0.0, 0.0, 0.14))
	draw_arc(center, radius, 0.0, TAU, 48, get_side_color().darkened(0.10), 1.6, true)
	draw_arc(center, radius - 2.2, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.16), 1.0, true)


func _draw_title_bar(rect: Rect2) -> void:
	var bar_rect := Rect2(rect.position + Vector2(2.0, 2.0), Vector2(rect.size.x - 4.0, TITLE_BAR_HEIGHT))
	draw_rect(bar_rect, get_title_bar_color(), true)
	draw_rect(bar_rect, Color(1.0, 1.0, 1.0, 0.10), false, 1.0)


func _draw_raised_border(rect: Rect2) -> void:
	var edge_color := get_side_color()
	draw_rect(rect, edge_color.darkened(0.15), false, 1.0)
	var top_left := edge_color.lightened(0.32)
	var bottom_right := edge_color.darkened(0.55)
	var right_x := rect.size.x - 1.0
	var bottom_y := rect.size.y - 1.0
	draw_line(Vector2(1.0, 1.0), Vector2(right_x - 1.0, 1.0), top_left, 1.0, true)
	draw_line(Vector2(1.0, 1.0), Vector2(1.0, bottom_y - 1.0), top_left, 1.0, true)
	draw_line(Vector2(right_x, 2.0), Vector2(right_x, bottom_y), bottom_right, 1.0, true)
	draw_line(Vector2(2.0, bottom_y), Vector2(right_x, bottom_y), bottom_right, 1.0, true)


func _draw_text_with_shadow(font: Font, baseline: Vector2, text: String, width: float, font_size: int, color: Color) -> void:
	draw_string(
		font,
		baseline + Vector2(1.0, 1.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		font_size,
		COLOR_TEXT_SHADOW
	)
	draw_string(
		font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		font_size,
		color
	)


func _is_damage_popup_visible() -> bool:
	if _damage_popup_value <= 0 or _damage_popup_tick < 0 or _visual_tick < _damage_popup_tick:
		return false
	return float(_visual_tick - _damage_popup_tick) <= DAMAGE_POPUP_DURATION_TICKS


func _damage_popup_progress() -> float:
	if not _is_damage_popup_visible():
		return 1.0
	var elapsed := float(_visual_tick - _damage_popup_tick)
	return clampf(elapsed / DAMAGE_POPUP_DURATION_TICKS, 0.0, 1.0)


func _damage_popup_alpha(progress: float) -> float:
	var fade_in := clampf(progress / 0.24, 0.0, 1.0)
	var fade_out := 1.0 - clampf((progress - 0.58) / 0.42, 0.0, 1.0)
	return clampf(minf(fade_in, fade_out), 0.0, 1.0)


func _draw_damage_popup(rect: Rect2, font: Font) -> void:
	var progress := _damage_popup_progress()
	var alpha := _damage_popup_alpha(progress)
	if alpha <= 0.0:
		return
	var rise := lerpf(0.0, DAMAGE_POPUP_RISE_PX, progress)
	var text := "-%d" % _damage_popup_value
	var text_color := COLOR_DAMAGE_TEXT
	text_color.a = alpha
	var shadow := COLOR_TEXT_SHADOW
	shadow.a = COLOR_TEXT_SHADOW.a * alpha
	var width := rect.size.x * 0.6
	var center := _token_circle_center(rect)
	var radius := _token_circle_radius(rect)
	var baseline := Vector2(center.x + radius * 0.58, center.y - radius * 0.70 - rise)
	draw_string(font, baseline + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, 24, shadow)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, width, 24, text_color)


func _draw_damage_particles(rect: Rect2) -> void:
	var progress := _damage_popup_progress()
	var alpha := _damage_popup_alpha(progress)
	if alpha <= 0.0:
		return
	var core_center := _token_circle_center(rect)
	var center := core_center + Vector2(0.0, -_token_circle_radius(rect) * 0.15)
	var travel := lerpf(4.0, 20.0, progress)
	var thickness := lerpf(2.2, 1.0, progress)
	for index in range(DAMAGE_PARTICLE_COUNT):
		var phase := float(index) / float(maxi(1, DAMAGE_PARTICLE_COUNT - 1))
		var angle := lerpf(-2.55, -0.60, phase)
		var direction := Vector2(cos(angle), sin(angle))
		var start := center + direction * (travel * 0.35)
		var end := center + direction * (travel * (0.85 + phase * 0.35))
		var spark := COLOR_DAMAGE_SPARK
		spark.a = alpha * (0.72 + 0.22 * (1.0 - phase))
		draw_line(start, end, spark, thickness, true)
		draw_circle(end, lerpf(1.8, 0.8, progress), spark)


func _token_circle_center(rect: Rect2) -> Vector2:
	return Vector2(rect.size.x * 0.5, rect.size.y * 0.62)


func _token_circle_radius(rect: Rect2) -> float:
	return maxf(20.0, minf(rect.size.x * 0.33, rect.size.y * 0.30))
