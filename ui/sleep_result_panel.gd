extends PanelContainer
class_name CatChaosSleepResultPanel

const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

var title_label: Label
var result_label: Label
var detail_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(360, 0)
	add_theme_stylebox_override("panel", _build_panel_style(Color(0.11, 0.13, 0.21, 0.90), Color(0.93, 0.90, 0.78, 0.40), 24, 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	title_label = Label.new()
	title_label.text = "BEDTIME RESULT"
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.modulate = Color(0.84, 0.88, 0.98)
	content.add_child(title_label)

	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 28)
	content.add_child(result_label)

	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(detail_label)

	hide_result()

func show_result(result: StringName) -> void:
	visible = true
	result_label.text = result
	if result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP:
		result_label.modulate = Color(0.75, 1.0, 0.83)
		detail_label.text = "The room settles down and the cat sleeps peacefully."
		detail_label.modulate = Color(0.90, 0.98, 0.92)
	else:
		result_label.modulate = Color(1.0, 0.79, 0.79)
		detail_label.text = "Something felt off tonight. Recover the stats before the next bedtime."
		detail_label.modulate = Color(0.98, 0.90, 0.90)

func hide_result() -> void:
	visible = false
	result_label.text = ""
	detail_label.text = ""

func _build_panel_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	return style
