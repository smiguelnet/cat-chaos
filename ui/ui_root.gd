extends Control

const HUD_SCRIPT = preload("res://ui/hud.gd")
const REQUEST_PANEL_SCRIPT = preload("res://ui/request_panel.gd")
const SLEEP_RESULT_PANEL_SCRIPT = preload("res://ui/sleep_result_panel.gd")
const FOOD_BAG_TEXTURE = preload("res://assets/sprites/cats/food-pack.png")
const CARE_TEXTURE_PATH := "res://assets/sprites/cats/sweet-love.png"
const HAND_CURSOR_TEXTURE = preload("res://assets/sprites/environment/hand-cursor.png")
const TITLE_FONT = preload("res://assets/ui/fonts/holiday-notes.otf")
const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const ACTION_PULSE_SPEED := 3.2
const ACTION_PULSE_SCALE := 0.06
const ACTION_PULSE_BRIGHTNESS := 0.10
const FOOD_BAG_PULSE_SPEED := 2.1
const FOOD_BAG_PULSE_SCALE := 0.12
const FOOD_BAG_PULSE_BRIGHTNESS := 0.12
const FOOD_BAG_PULSE_ROTATION := 0.03
const REQUEST_ICON_PRESSED_SCALE_MULTIPLIER := 0.9
const POINTING_CURSOR_REGION := Rect2(0, 0, 296, 326)
const OPEN_HAND_CURSOR_REGION := Rect2(308, 0, 343, 326)
const POINTING_CURSOR_HOTSPOT := Vector2(46, 34)
const OPEN_HAND_CURSOR_HOTSPOT := Vector2(259, 54)
const CURSOR_BASE_SCALE := 0.45
const CURSOR_PULSE_SPEED := 2.6
const CURSOR_PULSE_SCALE := 0.04
const CURSOR_ACTION_BRIGHTNESS := 0.08
const CURSOR_PRESSED_SCALE_MULTIPLIER := 0.84

signal feed_requested
signal pet_requested

var current_state
var last_sleep_result: StringName = &""

var hud
var request_panel
var sleep_result_panel
var feed_button: Button
var pet_button: Button
var food_bag_button: TextureButton
var care_button: TextureButton
var cursor_sprite: TextureRect
var ambiance_top: ColorRect
var ambiance_bottom: ColorRect
var pulse_time: float = 0.0
var open_hand_cursor_texture: AtlasTexture
var pointing_cursor_texture: AtlasTexture
var care_texture: Texture2D
var food_bag_pressed_visual: bool = false
var care_pressed_visual: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_process(true)
	_build_cursor_textures()
	care_texture = _load_png_texture(CARE_TEXTURE_PATH)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

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

	food_bag_button = TextureButton.new()
	food_bag_button.position = Vector2(974, 318)
	food_bag_button.size = Vector2(210, 210)
	food_bag_button.pivot_offset = food_bag_button.size * 0.5
	food_bag_button.ignore_texture_size = true
	food_bag_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	food_bag_button.texture_normal = FOOD_BAG_TEXTURE
	food_bag_button.texture_hover = FOOD_BAG_TEXTURE
	food_bag_button.texture_pressed = FOOD_BAG_TEXTURE
	food_bag_button.tooltip_text = "Feed the cat"
	food_bag_button.visible = false
	food_bag_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	food_bag_button.button_down.connect(_on_food_bag_button_down)
	food_bag_button.button_up.connect(_on_food_bag_button_up)
	food_bag_button.pressed.connect(_on_food_bag_pressed)
	overlay.add_child(food_bag_button)

	care_button = TextureButton.new()
	care_button.position = Vector2(962, 306)
	care_button.size = Vector2(228, 228)
	care_button.pivot_offset = care_button.size * 0.5
	care_button.ignore_texture_size = true
	care_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	care_button.texture_normal = care_texture
	care_button.texture_hover = care_texture
	care_button.texture_pressed = care_texture
	care_button.tooltip_text = "Care for the cat"
	care_button.visible = false
	care_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	care_button.button_down.connect(_on_care_button_down)
	care_button.button_up.connect(_on_care_button_up)
	care_button.pressed.connect(_on_care_button_pressed)
	overlay.add_child(care_button)

	cursor_sprite = TextureRect.new()
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.z_index = 100
	cursor_sprite.texture = open_hand_cursor_texture
	cursor_sprite.size = open_hand_cursor_texture.get_size()
	overlay.add_child(cursor_sprite)

	_sync_interaction_prompts()

func _process(delta: float) -> void:
	pulse_time += delta
	_update_button_pulse(feed_button, _should_pulse_button(&"FOOD"))
	_update_button_pulse(pet_button, _should_pulse_button(&"ATTENTION"))
	_update_food_bag_pulse()
	_update_care_pulse()
	_update_cursor_sprite()

func _exit_tree() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func apply_state(state) -> void:
	current_state = state
	hud.apply_state(state)
	_update_buttons(state.phase)
	_update_ambiance(state.phase)
	_sync_interaction_prompts()

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
	if current_state != null:
		current_state.phase = to_phase
		if to_phase == TICK_SYSTEM.PHASE_NIGHT:
			current_state.active_request = null
	_update_buttons(to_phase)
	_update_ambiance(to_phase)
	_sync_interaction_prompts()
	if to_phase != TICK_SYSTEM.PHASE_NIGHT:
		last_sleep_result = &""
		sleep_result_panel.hide_result()
	if to_phase != TICK_SYSTEM.PHASE_EVENING:
		request_panel.clear_request(false)

func on_request_generated(request_type: StringName, time_remaining: int) -> void:
	if current_state != null:
		current_state.active_request = {
			"type": request_type,
			"time_remaining": time_remaining
		}
	_sync_interaction_prompts()
	request_panel.show_request(request_type, time_remaining)
	request_panel.set_feedback("The cat wants %s right now." % _request_label(request_type), Color(0.99, 0.94, 0.78))

func on_request_completed(request_type: StringName) -> void:
	if current_state != null:
		current_state.active_request = null
	_sync_interaction_prompts()
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request completed cleanly." % _request_label(request_type), Color(0.79, 1.0, 0.84))

func on_request_failed(request_type: StringName) -> void:
	if current_state != null:
		current_state.active_request = null
	_sync_interaction_prompts()
	request_panel.clear_request(true)
	request_panel.set_feedback("%s request missed. Expect a mood drop." % _request_label(request_type), Color(1.0, 0.80, 0.80))

func on_sleep_evaluated(result: StringName, _state) -> void:
	last_sleep_result = result
	sleep_result_panel.show_result(result)

func _on_feed_button_pressed() -> void:
	if feed_button == null or feed_button.disabled:
		return
	_reset_button_pulse(feed_button)
	feed_requested.emit()

func _on_food_bag_pressed() -> void:
	if food_bag_button == null or not food_bag_button.visible:
		return
	_reset_food_bag_pulse()
	feed_requested.emit()

func _on_food_bag_button_down() -> void:
	food_bag_pressed_visual = true

func _on_food_bag_button_up() -> void:
	food_bag_pressed_visual = false

func _on_pet_button_pressed() -> void:
	if pet_button == null or pet_button.disabled:
		return
	_reset_button_pulse(pet_button)
	pet_requested.emit()

func _on_care_button_pressed() -> void:
	if care_button == null or not care_button.visible:
		return
	_reset_care_pulse()
	pet_requested.emit()

func _on_care_button_down() -> void:
	care_pressed_visual = true

func _on_care_button_up() -> void:
	care_pressed_visual = false

func _update_buttons(phase: StringName) -> void:
	var enabled: bool = TICK_SYSTEM.can_accept_actions(phase)
	if feed_button != null:
		feed_button.disabled = not enabled or _is_food_request_active()
		_set_button_enabled_style(feed_button, enabled, Color(0.97, 0.69, 0.31), Color(0.41, 0.24, 0.13))
	if pet_button != null:
		pet_button.disabled = not enabled
		_set_button_enabled_style(pet_button, enabled, Color(0.96, 0.49, 0.60), Color(0.35, 0.14, 0.20))
	if not enabled:
		_reset_button_pulse(feed_button)
		_reset_button_pulse(pet_button)
		_reset_food_bag_pulse()
		_reset_care_pulse()

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
	button.pivot_offset = button.custom_minimum_size * 0.5
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
	_reset_button_pulse(button)

func _update_button_pulse(button: Button, should_pulse: bool) -> void:
	if button == null:
		return
	if not button.visible or button.disabled or not should_pulse:
		_reset_button_pulse(button)
		return

	var pulse := (sin(pulse_time * TAU * 0.5 * ACTION_PULSE_SPEED) + 1.0) * 0.5
	var scale_boost := 1.0 + ACTION_PULSE_SCALE * pulse
	button.scale = Vector2(scale_boost, scale_boost)
	button.modulate = Color(
		1.0,
		1.0,
		1.0,
		1.0
	).lightened(ACTION_PULSE_BRIGHTNESS * pulse)

func _should_pulse_button(request_type: StringName) -> bool:
	if current_state == null:
		return false
	if current_state.phase != TICK_SYSTEM.PHASE_EVENING:
		return false
	if current_state.active_request == null:
		return false
	return current_state.active_request["type"] == request_type

func _reset_button_pulse(button: Button) -> void:
	if button == null:
		return
	button.scale = Vector2.ONE
	button.modulate = Color.WHITE

func _update_food_bag_pulse() -> void:
	if food_bag_button == null or not food_bag_button.visible:
		_reset_food_bag_pulse()
		return

	var pulse := (sin(pulse_time * TAU * 0.5 * FOOD_BAG_PULSE_SPEED) + 1.0) * 0.5
	var scale_boost := REQUEST_ICON_PRESSED_SCALE_MULTIPLIER if food_bag_pressed_visual else 1.0 + FOOD_BAG_PULSE_SCALE * pulse
	food_bag_button.scale = Vector2(scale_boost, scale_boost)
	food_bag_button.rotation = 0.0 if food_bag_pressed_visual else lerpf(-FOOD_BAG_PULSE_ROTATION, FOOD_BAG_PULSE_ROTATION, pulse)
	food_bag_button.modulate = Color.WHITE if food_bag_pressed_visual else Color.WHITE.lightened(FOOD_BAG_PULSE_BRIGHTNESS * pulse)

func _reset_food_bag_pulse() -> void:
	if food_bag_button == null:
		return
	food_bag_pressed_visual = false
	food_bag_button.scale = Vector2.ONE
	food_bag_button.rotation = 0.0
	food_bag_button.modulate = Color.WHITE

func _update_care_pulse() -> void:
	if care_button == null or not care_button.visible:
		_reset_care_pulse()
		return

	var pulse := (sin(pulse_time * TAU * 0.5 * FOOD_BAG_PULSE_SPEED) + 1.0) * 0.5
	var scale_boost := REQUEST_ICON_PRESSED_SCALE_MULTIPLIER if care_pressed_visual else 1.0 + FOOD_BAG_PULSE_SCALE * pulse
	care_button.scale = Vector2(scale_boost, scale_boost)
	care_button.rotation = 0.0 if care_pressed_visual else lerpf(-FOOD_BAG_PULSE_ROTATION, FOOD_BAG_PULSE_ROTATION, pulse)
	care_button.modulate = Color.WHITE if care_pressed_visual else Color.WHITE.lightened(FOOD_BAG_PULSE_BRIGHTNESS * pulse)

func _reset_care_pulse() -> void:
	if care_button == null:
		return
	care_pressed_visual = false
	care_button.scale = Vector2.ONE
	care_button.rotation = 0.0
	care_button.modulate = Color.WHITE

func _sync_interaction_prompts() -> void:
	var actions_enabled := current_state != null and TICK_SYSTEM.can_accept_actions(current_state.phase)
	var food_request_active := _is_food_request_active()
	var attention_request_active := _is_attention_request_active()

	if feed_button != null:
		feed_button.disabled = not actions_enabled or food_request_active
		feed_button.visible = not food_request_active
		feed_button.mouse_default_cursor_shape = Control.CURSOR_ARROW

	if pet_button != null:
		pet_button.disabled = not actions_enabled
		pet_button.visible = not attention_request_active
		pet_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if actions_enabled and attention_request_active else Control.CURSOR_ARROW

	if food_bag_button != null:
		food_bag_button.visible = actions_enabled and food_request_active
		food_bag_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not food_bag_button.visible:
			_reset_food_bag_pulse()

	if care_button != null:
		care_button.visible = actions_enabled and attention_request_active
		care_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if not care_button.visible:
			_reset_care_pulse()

func _update_cursor_sprite() -> void:
	if cursor_sprite == null:
		return

	var cursor_texture: AtlasTexture = pointing_cursor_texture if _is_action_needed() else open_hand_cursor_texture
	var hotspot := POINTING_CURSOR_HOTSPOT if _is_action_needed() else OPEN_HAND_CURSOR_HOTSPOT
	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var pulse := (sin(pulse_time * TAU * 0.5 * CURSOR_PULSE_SPEED) + 1.0) * 0.5
	var scale_boost := CURSOR_PRESSED_SCALE_MULTIPLIER if is_pressed else 1.0 + CURSOR_PULSE_SCALE * pulse
	var cursor_scale := CURSOR_BASE_SCALE * scale_boost

	cursor_sprite.texture = cursor_texture
	cursor_sprite.size = cursor_texture.get_size()
	cursor_sprite.scale = Vector2.ONE * cursor_scale
	cursor_sprite.position = get_viewport().get_mouse_position() - hotspot * cursor_scale
	cursor_sprite.modulate = Color.WHITE.lightened(CURSOR_ACTION_BRIGHTNESS * pulse if _is_action_needed() and not is_pressed else 0.0)

func _is_food_request_active() -> bool:
	return _active_request_type() == &"FOOD"

func _is_attention_request_active() -> bool:
	return _active_request_type() == &"ATTENTION"

func _is_action_needed() -> bool:
	return _active_request_type() != &""

func _active_request_type() -> StringName:
	if current_state == null:
		return &""
	if current_state.phase != TICK_SYSTEM.PHASE_EVENING:
		return &""
	if current_state.active_request == null:
		return &""
	return current_state.active_request["type"]

func _build_cursor_textures() -> void:
	open_hand_cursor_texture = _make_cursor_texture(OPEN_HAND_CURSOR_REGION)
	pointing_cursor_texture = _make_cursor_texture(POINTING_CURSOR_REGION)

func _make_cursor_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = HAND_CURSOR_TEXTURE
	texture.region = region
	return texture

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

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
