extends PanelContainer
class_name CatChaosHud

const PANEL_BG := Color(0.10, 0.10, 0.16, 0.84)
const PANEL_BORDER := Color(0.99, 0.90, 0.74, 0.52)
const HEADER_BG := Color(0.96, 0.78, 0.49, 0.18)
const TEXT_MAIN := Color(0.98, 0.96, 0.90)
const TEXT_MUTED := Color(0.86, 0.82, 0.74)

var phase_label: Label
var timer_label: Label
var fullness_bar: ProgressBar
var fullness_value: Label
var happiness_bar: ProgressBar
var happiness_value: Label
var calmness_bar: ProgressBar
var calmness_value: Label

func _ready() -> void:
	custom_minimum_size = Vector2(336, 0)
	add_theme_stylebox_override("panel", _build_panel_style(PANEL_BG, PANEL_BORDER, 18, 2))

	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 16)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 18)
	add_child(root)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _build_panel_style(HEADER_BG, Color(1, 1, 1, 0.08), 14, 1))
	content.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 14)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_right", 14)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)

	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 12)
	header_margin.add_child(header_row)

	phase_label = _make_chip_label(21, TEXT_MAIN)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(phase_label)

	timer_label = _make_chip_label(16, TEXT_MUTED)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(timer_label)

	content.add_child(_make_stat_card(
		"FULLNESS",
		"Keep the bowl and belly happy.",
		Color(0.95, 0.63, 0.34),
		"fullness_bar",
		"fullness_value"
	))
	content.add_child(_make_stat_card(
		"HAPPINESS",
		"Attention keeps the mood up.",
		Color(0.96, 0.45, 0.58),
		"happiness_bar",
		"happiness_value"
	))
	content.add_child(_make_stat_card(
		"CALMNESS",
		"High calmness means a gentler night.",
		Color(0.41, 0.78, 0.72),
		"calmness_bar",
		"calmness_value"
	))

func apply_state(state) -> void:
	phase_label.text = _phase_title(state.phase)
	timer_label.text = "%ss left" % state.phase_time_remaining
	_apply_bar_state(fullness_bar, fullness_value, state.fullness)
	_apply_bar_state(happiness_bar, happiness_value, state.happiness)
	_apply_bar_state(calmness_bar, calmness_value, state.calmness)

func _make_stat_card(title: String, subtitle: String, accent: Color, bar_name: String, value_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _build_panel_style(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.06), 14, 1))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	content.add_child(top_row)

	var accent_dot := ColorRect.new()
	accent_dot.custom_minimum_size = Vector2(10, 10)
	accent_dot.color = accent
	top_row.add_child(accent_dot)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = TEXT_MAIN
	top_row.add_child(title_label)

	var value_label := Label.new()
	value_label.name = value_name
	value_label.text = "0 / 100"
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 17)
	value_label.modulate = TEXT_MAIN
	top_row.add_child(value_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.modulate = TEXT_MUTED
	content.add_child(subtitle_label)

	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.add_theme_stylebox_override("background", _build_panel_style(Color(0, 0, 0, 0.22), Color(1, 1, 1, 0.08), 8, 1))
	bar.add_theme_stylebox_override("fill", _build_panel_style(accent, accent.lightened(0.18), 8, 1))
	content.add_child(bar)

	set(bar_name, bar)
	set(value_name, value_label)
	return card

func _apply_bar_state(bar: ProgressBar, value_label: Label, value: int) -> void:
	bar.value = value
	value_label.text = "%s / 100" % value

func _make_chip_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _phase_title(phase: StringName) -> String:
	if phase == &"DAY":
		return "DAYTIME CARE"
	if phase == &"EVENING":
		return "EVENING RUSH"
	return "NIGHT CHECK"

func _build_panel_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	return style
