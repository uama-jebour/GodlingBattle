extends Control

const CARD_COLOR_READY := Color(0.113725, 0.164706, 0.196078, 0.94)
const CARD_COLOR_TRIGGERED := Color(0.196078, 0.27451, 0.176471, 0.98)
const STATE_COLOR_READY := Color(0.78, 0.86, 0.94, 1.0)
const STATE_COLOR_TRIGGERED := Color(0.98, 0.93, 0.66, 1.0)

var strategy_name := "未知战技"
var cooldown_ratio := 0.0
var cooldown_remaining_seconds := 0.0
var cooldown_total_seconds := 0.0
var is_triggered := false

@onready var _card_bg: ColorRect = get_node_or_null("CardBg") as ColorRect
@onready var _name_label: Label = get_node_or_null("NameLabel") as Label
@onready var _state_label: Label = get_node_or_null("StateLabel") as Label
@onready var _cooldown_label: Label = get_node_or_null("CooldownLabel") as Label
@onready var _cooldown_fill: ColorRect = get_node_or_null("CooldownFill") as ColorRect


func _ready() -> void:
	_sync_view()


func apply_state(state: Dictionary) -> void:
	strategy_name = str(state.get("name", "未知战技"))
	cooldown_ratio = clampf(float(state.get("cooldown_ratio", 0.0)), 0.0, 1.0)
	cooldown_remaining_seconds = maxf(0.0, float(state.get("cooldown_remaining_seconds", 0.0)))
	cooldown_total_seconds = maxf(0.0, float(state.get("cooldown_total_seconds", 0.0)))
	is_triggered = bool(state.get("triggered", false))
	_sync_view()


func _sync_view() -> void:
	if _name_label != null:
		_name_label.text = strategy_name
	if _state_label != null:
		_state_label.text = _state_text()
		_state_label.modulate = STATE_COLOR_TRIGGERED if is_triggered else STATE_COLOR_READY
	if _cooldown_label != null:
		_cooldown_label.text = "冷却 %.1fs / %.1fs" % [cooldown_remaining_seconds, cooldown_total_seconds]
	if _cooldown_fill != null:
		_cooldown_fill.anchor_top = 1.0 - cooldown_ratio
		_cooldown_fill.anchor_bottom = 1.0
		_cooldown_fill.offset_top = 0.0
		_cooldown_fill.offset_bottom = 0.0
		_cooldown_fill.visible = cooldown_ratio > 0.0
	if _card_bg != null:
		_card_bg.color = CARD_COLOR_TRIGGERED if is_triggered else CARD_COLOR_READY


func _state_text() -> String:
	if is_triggered:
		return "已触发"
	if cooldown_remaining_seconds > 0.05:
		return "冷却中"
	return "就绪"
