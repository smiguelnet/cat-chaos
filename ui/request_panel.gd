extends PanelContainer
class_name CatChaosRequestPanel

const TITLE_FONT = preload("res://assets/ui/fonts/holiday-notes.otf")
const PANEL_BG := Color(0.17, 0.11, 0.16, 0.92)
const PANEL_BORDER := Color(1.00, 0.77, 0.53, 0.72)
const FOOD_COLOR := Color(0.97, 0.69, 0.31)
const ATTENTION_COLOR := Color(0.96, 0.49, 0.60)

var header_label: Label
var title_label: Label
var countdown_label: Label
var countdown_bar: ProgressBar
var feedback_label: Label
var current_request_type: StringName = &""

func _ready() -> void:
	custom_minimum_size = Vector2(350, 0)
	add_theme_stylebox_override("panel", _build_panel_style(PANEL_BG, PANEL_BORDER, 22, 2))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	header_label = Label.new()
	header_label.text = "CAT REQUEST"
	header_label.add_theme_font_override("font", TITLE_FONT)
	header_label.add_theme_font_size_override("font_size", 13)
	header_label.modulate = Color(1.0, 0.88, 0.72)
	content.add_child(header_label)

	title_label = Label.new()
	title_label.add_theme_font_override("font", TITLE_FONT)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.modulate = Color(0.99, 0.97, 0.93)
	content.add_child(title_label)

	countdown_label = Label.new()
	countdown_label.add_theme_font_size_override("font_size", 15)
	countdown_label.modulate = Color(0.87, 0.82, 0.76)
	content.add_child(countdown_label)

	countdown_bar = ProgressBar.new()
	countdown_bar.min_value = 0
	countdown_bar.max_value = 5
	countdown_bar.show_percentage = false
	countdown_bar.custom_minimum_size = Vector2(0, 18)
	countdown_bar.add_theme_stylebox_override("background", _build_panel_style(Color(0, 0, 0, 0.24), Color(1, 1, 1, 0.08), 9, 1))
	content.add_child(countdown_bar)

	feedback_label = Label.new()
	feedback_label.add_theme_font_size_override("font_size", 14)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(feedback_label)

	clear_request(false)

func show_request(request_type: StringName, time_remaining: int) -> void:
	visible = true
	current_request_type = request_type
	title_label.visible = true
	countdown_label.visible = true
	countdown_bar.visible = true
	title_label.text = _request_heading(request_type)
	countdown_label.text = "Resolve this in %ss" % time_remaining
	countdown_bar.value = time_remaining
	var accent := _request_color(request_type)
	countdown_bar.add_theme_stylebox_override("fill", _build_panel_style(accent, accent.lightened(0.12), 9, 1))
	feedback_label.text = _request_description(request_type)
	feedback_label.modulate = Color(0.95, 0.90, 0.83)

func clear_request(preserve_feedback: bool = true) -> void:
	current_request_type = &""
	title_label.visible = false
	countdown_label.visible = false
	countdown_bar.visible = false
	countdown_bar.value = 0
	if not preserve_feedback:
		feedback_label.text = "No active request."
		feedback_label.modulate = Color(0.75, 0.73, 0.73)

func set_feedback(text: String, color: Color = Color.WHITE) -> void:
	feedback_label.text = text
	feedback_label.modulate = color

func _request_heading(request_type: StringName) -> String:
	if request_type == &"FOOD":
		return "Hungry Cat"
	return "Needs Attention"

func _request_description(request_type: StringName) -> String:
	if request_type == &"FOOD":
		return "Serve food before the timer expires."
	return "Pet the cat before the mood drops."

func _request_color(request_type: StringName) -> Color:
	if request_type == &"FOOD":
		return FOOD_COLOR
	return ATTENTION_COLOR

func _build_panel_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	return style
