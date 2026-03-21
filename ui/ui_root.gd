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

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 20)
	root_margin.add_theme_constant_override("margin_top", 20)
	root_margin.add_theme_constant_override("margin_right", 20)
	root_margin.add_theme_constant_override("margin_bottom", 20)
	add_child(root_margin)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	root_margin.add_child(overlay)

	hud = HUD_SCRIPT.new()
	hud.position = Vector2.ZERO
	overlay.add_child(hud)

	request_panel = REQUEST_PANEL_SCRIPT.new()
	request_panel.position = Vector2(450, 20)
	overlay.add_child(request_panel)

	sleep_result_panel = SLEEP_RESULT_PANEL_SCRIPT.new()
	sleep_result_panel.position = Vector2(460, 86)
	overlay.add_child(sleep_result_panel)

	var button_box := HBoxContainer.new()
	button_box.position = Vector2(20, 590)
	button_box.add_theme_constant_override("separation", 12)
	button_box.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(button_box)

	feed_button = Button.new()
	feed_button.text = "Feed [F]"
	feed_button.custom_minimum_size = Vector2(140, 52)
	feed_button.pressed.connect(_on_feed_button_pressed)
	button_box.add_child(feed_button)

	pet_button = Button.new()
	pet_button.text = "Pet [P]"
	pet_button.custom_minimum_size = Vector2(140, 52)
	pet_button.pressed.connect(_on_pet_button_pressed)
	button_box.add_child(pet_button)

func apply_state(state) -> void:
	current_state = state
	hud.apply_state(state)
	_update_buttons(state.phase)

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
	if to_phase != TICK_SYSTEM.PHASE_NIGHT:
		last_sleep_result = &""
		sleep_result_panel.hide_result()
	if to_phase != TICK_SYSTEM.PHASE_EVENING:
		request_panel.clear_request(false)

func on_request_generated(request_type: StringName, time_remaining: int) -> void:
	request_panel.show_request(request_type, time_remaining)
	request_panel.set_feedback("The cat wants %s." % _request_label(request_type), Color("fff0b0"))

func on_request_completed(request_type: StringName) -> void:
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request completed." % _request_label(request_type), Color("c8ffd4"))

func on_request_failed(request_type: StringName) -> void:
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request failed." % _request_label(request_type), Color("ffd0d0"))

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

func _request_label(request_type: StringName) -> String:
	if request_type == &"FOOD":
		return "Food"
	return "Attention"
