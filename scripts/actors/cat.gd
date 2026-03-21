extends Node2D
class_name CatPresentation

var current_phase: StringName = TickSystem.PHASE_DAY
var mood: StringName = &"IDLE"
var active_request_type: StringName = &""
var sleep_result: StringName = &""

func _ready() -> void:
	queue_redraw()

func apply_state(state: GameState) -> void:
	current_phase = state.phase
	if state.active_request == null and current_phase != TickSystem.PHASE_NIGHT and mood == &"REQUESTING":
		mood = &"IDLE"
	if current_phase == TickSystem.PHASE_NIGHT:
		mood = &"SLEEPING"
	active_request_type = &"" if state.active_request == null else state.active_request["type"]
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	if to_phase == TickSystem.PHASE_DAY:
		mood = &"IDLE"
		sleep_result = &""
	elif to_phase == TickSystem.PHASE_NIGHT:
		mood = &"SLEEPING"
	queue_redraw()

func on_request_generated(request_type: StringName, _time_remaining: int) -> void:
	active_request_type = request_type
	mood = &"REQUESTING"
	queue_redraw()

func on_request_completed(_request_type: StringName) -> void:
	active_request_type = &""
	mood = &"SATISFIED"
	queue_redraw()

func on_request_failed(_request_type: StringName) -> void:
	active_request_type = &""
	mood = &"UPSET"
	queue_redraw()

func on_sleep_evaluated(result: StringName, _state: GameState) -> void:
	sleep_result = result
	mood = &"SLEEPING"
	queue_redraw()

func _draw() -> void:
	var fur_color := Color("bd8857")
	if current_phase == TickSystem.PHASE_EVENING:
		fur_color = Color("c08f63")
	elif current_phase == TickSystem.PHASE_NIGHT:
		fur_color = Color("8c7b87")

	if mood == &"SATISFIED":
		fur_color = Color("d9a76a")
	elif mood == &"UPSET":
		fur_color = Color("8e6c5a")

	draw_circle(Vector2(0, 10), 74.0, fur_color)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-52, -16), Vector2(-20, -86), Vector2(0, -8)]),
		fur_color
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(52, -16), Vector2(20, -86), Vector2(0, -8)]),
		fur_color
	)

	var eye_y := -4.0
	if mood == &"SLEEPING":
		draw_line(Vector2(-26, eye_y), Vector2(-10, eye_y + 2), Color("1f1a17"), 5.0)
		draw_line(Vector2(10, eye_y + 2), Vector2(26, eye_y), Color("1f1a17"), 5.0)
	else:
		draw_circle(Vector2(-20, eye_y), 6.0, Color("241915"))
		draw_circle(Vector2(20, eye_y), 6.0, Color("241915"))

	draw_colored_polygon(
		PackedVector2Array([Vector2(0, 12), Vector2(-9, 24), Vector2(9, 24)]),
		Color("eba494")
	)
	draw_arc(Vector2(0, 30), 18.0, 0.2, PI - 0.2, 16, Color("241915"), 3.0)

	if active_request_type == &"FOOD":
		draw_circle(Vector2(-94, -54), 16.0, Color("ffb454"))
	elif active_request_type == &"ATTENTION":
		draw_circle(Vector2(94, -54), 16.0, Color("ff7f7f"))

	if sleep_result == SleepEvaluator.RESULT_GOOD_SLEEP:
		draw_arc(Vector2(0, -104), 18.0, 0.2, PI - 0.2, 16, Color("fff3b1"), 3.0)
	elif sleep_result == SleepEvaluator.RESULT_DISTURBED_SLEEP:
		draw_line(Vector2(-16, -118), Vector2(0, -98), Color("d4b4ff"), 3.0)
		draw_line(Vector2(0, -98), Vector2(16, -118), Color("d4b4ff"), 3.0)
