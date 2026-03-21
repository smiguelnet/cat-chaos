extends Control

const HUD_SCRIPT = preload("res://ui/hud.gd")
const REQUEST_PANEL_SCRIPT = preload("res://ui/request_panel.gd")
const SLEEP_RESULT_PANEL_SCRIPT = preload("res://ui/sleep_result_panel.gd")
const TICK_SYSTEM = preload("res://systems/tick_system.gd")

signal feed_requested
signal pet_requested

var current_state
var last_sleep_result: StringName = &""

var hud
var request_panel
var sleep_result_panel
var feed_button: Button
var pet_button: Button
var action_panel: PanelContainer
var ambiance_top: ColorRect
var ambiance_bottom: ColorRect

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	ambiance_top = ColorRect.new()
	ambiance_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ambiance_top.custom_minimum_size = Vector2(0, 180)
	ambiance_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambiance_top)

	ambiance_bottom = ColorRect.new()
	ambiance_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ambiance_bottom.custom_minimum_size = Vector2(0, 220)
	ambiance_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambiance_bottom)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 24)
	root_margin.add_theme_constant_override("margin_top", 20)
	root_margin.add_theme_constant_override("margin_right", 24)
	root_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(root_margin)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	root_margin.add_child(overlay)

	hud = HUD_SCRIPT.new()
	hud.position = Vector2(0, 0)
	overlay.add_child(hud)

	request_panel = REQUEST_PANEL_SCRIPT.new()
	request_panel.position = Vector2(420, 18)
	overlay.add_child(request_panel)

	sleep_result_panel = SLEEP_RESULT_PANEL_SCRIPT.new()
	sleep_result_panel.position = Vector2(420, 138)
	overlay.add_child(sleep_result_panel)

	action_panel = PanelContainer.new()
	action_panel.position = Vector2(0, 566)
	action_panel.custom_minimum_size = Vector2(338, 110)
	action_panel.add_theme_stylebox_override("panel", _build_panel_style(Color(0.09, 0.09, 0.14, 0.86), Color(0.99, 0.90, 0.74, 0.42), 22, 2))
	overlay.add_child(action_panel)

	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 16)
	action_margin.add_theme_constant_override("margin_top", 14)
	action_margin.add_theme_constant_override("margin_right", 16)
	action_margin.add_theme_constant_override("margin_bottom", 14)
	action_panel.add_child(action_margin)

	var action_content := VBoxContainer.new()
	action_content.add_theme_constant_override("separation", 10)
	action_margin.add_child(action_content)

	var action_title := Label.new()
	action_title.text = "CARE ACTIONS"
	action_title.add_theme_font_size_override("font_size", 14)
	action_title.modulate = Color(0.98, 0.91, 0.78)
	action_content.add_child(action_title)

	var button_box := HBoxContainer.new()
	button_box.add_theme_constant_override("separation", 12)
	button_box.mouse_filter = Control.MOUSE_FILTER_PASS
	action_content.add_child(button_box)

	feed_button = _create_action_button("Feed [F]", Color(0.97, 0.69, 0.31), Color(0.41, 0.24, 0.13))
	feed_button.pressed.connect(_on_feed_button_pressed)
	button_box.add_child(feed_button)

	pet_button = _create_action_button("Pet [P]", Color(0.96, 0.49, 0.60), Color(0.35, 0.14, 0.20))
	pet_button.pressed.connect(_on_pet_button_pressed)
	button_box.add_child(pet_button)

func apply_state(state) -> void:
	current_state = state
	hud.apply_state(state)
	_update_buttons(state.phase)
	_update_ambiance(state.phase)

	if state.phase == TICK_SYSTEM.PHASE_EVENING and state.active_request != null:
		request_panel.show_request(state.active_request["type"], state.active_request["time_remaining"])
	elif state.phase == TICK_SYSTEM.PHASE_EVENING:
		request_panel.clear_request(true)
	else:
		request_panel.clear_request(false)

	if state.phase == TICK_SYSTEM.PHASE_NIGHT and last_sleep_result != &"":
		sleep_result_panel.show_result(last_sleep_result)
	elif state.phase != TICK_SYSTEM.PHASE_NIGHT:
		sleep_result_panel.hide_result()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	_update_buttons(to_phase)
	_update_ambiance(to_phase)
	if to_phase != TICK_SYSTEM.PHASE_NIGHT:
		last_sleep_result = &""
		sleep_result_panel.hide_result()
	if to_phase != TICK_SYSTEM.PHASE_EVENING:
		request_panel.clear_request(false)

func on_request_generated(request_type: StringName, time_remaining: int) -> void:
	request_panel.show_request(request_type, time_remaining)
	request_panel.set_feedback("The cat wants %s right now." % _request_label(request_type), Color(0.99, 0.94, 0.78))

func on_request_completed(request_type: StringName) -> void:
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request completed cleanly." % _request_label(request_type), Color(0.79, 1.0, 0.84))

func on_request_failed(request_type: StringName) -> void:
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request missed. Expect a mood drop." % _request_label(request_type), Color(1.0, 0.80, 0.80))

func on_sleep_evaluated(result: StringName, _state) -> void:
	last_sleep_result = result
	sleep_result_panel.show_result(result)

func _on_feed_button_pressed() -> void:
	if feed_button.disabled:
		return
	feed_requested.emit()

func _on_pet_button_pressed() -> void:
	if pet_button.disabled:
		return
	pet_requested.emit()

func _update_buttons(phase: StringName) -> void:
	var enabled: bool = TICK_SYSTEM.can_accept_actions(phase)
	feed_button.disabled = not enabled
	pet_button.disabled = not enabled
	_set_button_enabled_style(feed_button, enabled, Color(0.97, 0.69, 0.31), Color(0.41, 0.24, 0.13))
	_set_button_enabled_style(pet_button, enabled, Color(0.96, 0.49, 0.60), Color(0.35, 0.14, 0.20))

func _update_ambiance(phase: StringName) -> void:
	if phase == TICK_SYSTEM.PHASE_DAY:
		ambiance_top.color = Color(0.98, 0.90, 0.69, 0.14)
		ambiance_bottom.color = Color(0.55, 0.32, 0.14, 0.10)
	elif phase == TICK_SYSTEM.PHASE_EVENING:
		ambiance_top.color = Color(0.89, 0.54, 0.33, 0.16)
		ambiance_bottom.color = Color(0.40, 0.16, 0.12, 0.13)
	else:
		ambiance_top.color = Color(0.32, 0.42, 0.66, 0.16)
		ambiance_bottom.color = Color(0.05, 0.07, 0.12, 0.24)

func _create_action_button(text: String, fill: Color, text_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(147, 52)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color.darkened(0.15))
	button.add_theme_stylebox_override("normal", _build_panel_style(fill, fill.lightened(0.12), 18, 2))
	button.add_theme_stylebox_override("hover", _build_panel_style(fill.lightened(0.06), fill.lightened(0.16), 18, 2))
	button.add_theme_stylebox_override("pressed", _build_panel_style(fill.darkened(0.06), fill.lightened(0.08), 18, 2))
	button.add_theme_stylebox_override("disabled", _build_panel_style(Color(0.36, 0.37, 0.43, 0.75), Color(1, 1, 1, 0.08), 18, 1))
	return button

func _set_button_enabled_style(button: Button, enabled: bool, fill: Color, text_color: Color) -> void:
	if enabled:
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", text_color)
	else:
		button.add_theme_color_override("font_color", Color(0.83, 0.84, 0.89))
		button.add_theme_color_override("font_hover_color", Color(0.83, 0.84, 0.89))

func _build_panel_style(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	return style

func _request_label(request_type: StringName) -> String:
	if request_type == &"FOOD":
		return "Food"
	return "Attention"
