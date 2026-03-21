extends Node2D
class_name EnvironmentPresentation

const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

var current_phase: StringName = TICK_SYSTEM.PHASE_DAY
var last_sleep_result: StringName = &""
var request_failed_flash: bool = false

func _ready() -> void:
	queue_redraw()

func apply_state(state) -> void:
	current_phase = state.phase
	if state.phase != TICK_SYSTEM.PHASE_EVENING:
		request_failed_flash = false
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	request_failed_flash = false
	if to_phase != TICK_SYSTEM.PHASE_NIGHT:
		last_sleep_result = &""
	queue_redraw()

func on_request_failed(_request_type: StringName) -> void:
	request_failed_flash = true
	queue_redraw()

func on_sleep_evaluated(result: StringName, _state) -> void:
	last_sleep_result = result
	request_failed_flash = false
	queue_redraw()

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var sky_color := Color("f5dcae")
	var floor_color := Color("b98754")
	var accent_color := Color("f8efcf")

	match current_phase:
		TICK_SYSTEM.PHASE_DAY:
			sky_color = Color("f5dcae")
			floor_color = Color("b98754")
			accent_color = Color("fff7de")
		TICK_SYSTEM.PHASE_EVENING:
			sky_color = Color("d78f63")
			floor_color = Color("9e6c4e")
			accent_color = Color("ffd0a6")
		TICK_SYSTEM.PHASE_NIGHT:
			sky_color = Color("34435d")
			floor_color = Color("516072")
			accent_color = Color("f7dd93")

	draw_rect(Rect2(Vector2.ZERO, viewport_size), sky_color, true)
	draw_rect(Rect2(0, viewport_size.y * 0.72, viewport_size.x, viewport_size.y * 0.28), floor_color, true)
	draw_rect(Rect2(64, 92, 220, 180), Color(1.0, 1.0, 1.0, 0.18), true)
	draw_circle(Vector2(viewport_size.x - 140, 120), 32.0, accent_color)
	draw_rect(Rect2(viewport_size.x - 280, 320, 180, 160), Color("7e5e4f"), true)
	draw_rect(Rect2(96, 470, 180, 110), Color("d9c4a1"), true)

	if request_failed_flash:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.56, 0.56, 0.12), true)

	if current_phase == TICK_SYSTEM.PHASE_NIGHT:
		var overlay_color := Color(0.76, 0.94, 0.76, 0.16) if last_sleep_result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP else Color(0.94, 0.76, 0.76, 0.16)
		if last_sleep_result != &"":
			draw_rect(Rect2(Vector2.ZERO, viewport_size), overlay_color, true)
