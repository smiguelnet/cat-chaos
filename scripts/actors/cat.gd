extends Node2D
class_name CatPresentation

const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

var current_phase: StringName = TICK_SYSTEM.PHASE_DAY
var mood: StringName = &"IDLE"
var active_request_type: StringName = &""
var sleep_result: StringName = &""
var animation_time: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()

func apply_state(state) -> void:
	current_phase = state.phase
	if state.active_request == null and current_phase != TICK_SYSTEM.PHASE_NIGHT and mood == &"REQUESTING":
		mood = &"IDLE"
	if current_phase == TICK_SYSTEM.PHASE_NIGHT:
		mood = &"FURIOUS" if sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	active_request_type = &"" if state.active_request == null else state.active_request["type"]
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	if to_phase == TICK_SYSTEM.PHASE_DAY:
		mood = &"IDLE"
		sleep_result = &""
	elif to_phase == TICK_SYSTEM.PHASE_NIGHT:
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

func on_sleep_evaluated(result: StringName, _state) -> void:
	sleep_result = result
	mood = &"FURIOUS" if result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	queue_redraw()

func _draw() -> void:
	var fur_color := _fur_color()
	var shadow_alpha := 0.16 if current_phase != TICK_SYSTEM.PHASE_NIGHT else 0.24
	var bob := _bob_amount()
	var tail_sway := _tail_sway()
	var rage_shake := _rage_shake()
	var ear_tilt := sin(animation_time * 1.9) * 0.08
	if mood == &"FURIOUS":
		ear_tilt = -0.34 + sin(animation_time * 9.0) * 0.03
	var blink := _blink_amount()
	var head_offset := Vector2(0, -8 + bob * 0.7) + rage_shake
	var body_center := Vector2(0, 18 + bob) + rage_shake * 0.7
	var body_scale := Vector2(1.0, 1.0 + _breath_amount() * 0.03)

	draw_set_transform(Vector2(0, 100), 0.0, Vector2(2.6, 0.44))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_tail(body_center, tail_sway, fur_color)
	_draw_body(body_center, body_scale, fur_color)
	_draw_paws(body_center, fur_color)
	_draw_head(head_offset, fur_color, ear_tilt, blink)
	_draw_face(head_offset, blink)
	_draw_status_marks(head_offset)

func _draw_body(center: Vector2, scale_xy: Vector2, fur_color: Color) -> void:
	draw_set_transform(center, 0.0, scale_xy)
	draw_circle(Vector2(0, 0), 76.0, fur_color)
	draw_circle(Vector2(-30, 16), 24.0, fur_color.darkened(0.04))
	draw_circle(Vector2(30, 16), 24.0, fur_color.darkened(0.04))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_paws(center: Vector2, fur_color: Color) -> void:
	var paw_lift := 0.0
	if mood == &"REQUESTING":
		paw_lift = sin(animation_time * 6.0) * 5.0
	elif mood == &"SATISFIED":
		paw_lift = sin(animation_time * 4.0) * 2.0

	draw_circle(center + Vector2(-22, 58 - paw_lift), 14.0, fur_color.lightened(0.04))
	draw_circle(center + Vector2(22, 58 + paw_lift * 0.35), 14.0, fur_color.lightened(0.04))

func _draw_head(center: Vector2, fur_color: Color, ear_tilt: float, blink: float) -> void:
	draw_circle(center, 58.0, fur_color.lightened(0.02))

	var left_ear := PackedVector2Array([
		center + Vector2(-36, -18),
		center + Vector2(-12 + ear_tilt * 18.0, -88),
		center + Vector2(2, -20),
	])
	var right_ear := PackedVector2Array([
		center + Vector2(36, -18),
		center + Vector2(12 - ear_tilt * 18.0, -88),
		center + Vector2(-2, -20),
	])
	draw_colored_polygon(left_ear, fur_color)
	draw_colored_polygon(right_ear, fur_color)

	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(-28, -24),
			center + Vector2(-12 + ear_tilt * 10.0, -66 + abs(ear_tilt) * 10.0),
			center + Vector2(-2, -22),
		]),
		Color("f0ae9f")
	)
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(28, -24),
			center + Vector2(12 - ear_tilt * 10.0, -66 + abs(ear_tilt) * 10.0),
			center + Vector2(2, -22),
		]),
		Color("f0ae9f")
	)

	if mood == &"SLEEPING" and blink >= 1.0:
		draw_arc(center + Vector2(0, 18), 20.0, 0.3, PI - 0.3, 18, Color("241915"), 3.0)

func _draw_face(center: Vector2, blink: float) -> void:
	var eye_color := Color("241915")
	var eye_y := center.y - 8.0
	var eye_open := 1.0 - blink

	if mood == &"SLEEPING":
		draw_line(center + Vector2(-22, -8), center + Vector2(-8, -6), eye_color, 4.0)
		draw_line(center + Vector2(8, -6), center + Vector2(22, -8), eye_color, 4.0)
	elif mood == &"FURIOUS":
		draw_line(center + Vector2(-28, -2), center + Vector2(-10, -12), eye_color, 5.0)
		draw_line(center + Vector2(10, -12), center + Vector2(28, -2), eye_color, 5.0)
		draw_line(center + Vector2(-30, -16), center + Vector2(-6, -22), Color("241915", 0.9), 3.0)
		draw_line(center + Vector2(6, -22), center + Vector2(30, -16), Color("241915", 0.9), 3.0)
	else:
		if eye_open < 0.35:
			draw_line(center + Vector2(-24, -8), center + Vector2(-10, -7), eye_color, 4.0)
			draw_line(center + Vector2(10, -7), center + Vector2(24, -8), eye_color, 4.0)
		else:
			draw_circle(Vector2(center.x - 18, eye_y), 5.0 + eye_open, eye_color)
			draw_circle(Vector2(center.x + 18, eye_y), 5.0 + eye_open, eye_color)

	var nose_center := center + Vector2(0, 10)
	draw_colored_polygon(
		PackedVector2Array([
			nose_center + Vector2(0, 0),
			nose_center + Vector2(-9, 11),
			nose_center + Vector2(9, 11),
		]),
		Color("eba494")
	)

	if mood == &"FURIOUS":
		draw_arc(center + Vector2(0, 34), 10.0, PI + 0.12, TAU - 0.12, 14, eye_color, 4.0)
		draw_line(center + Vector2(-8, 24), center + Vector2(-12, 38), eye_color, 2.0)
		draw_line(center + Vector2(8, 24), center + Vector2(12, 38), eye_color, 2.0)
	elif mood == &"UPSET":
		draw_arc(center + Vector2(0, 28), 12.0, PI + 0.3, TAU - 0.3, 12, eye_color, 3.0)
	elif mood == &"SATISFIED":
		draw_arc(center + Vector2(0, 24), 16.0, 0.3, PI - 0.3, 16, eye_color, 3.0)
	else:
		draw_arc(center + Vector2(0, 26), 14.0, 0.2, PI - 0.2, 16, eye_color, 3.0)

	draw_line(center + Vector2(-6, 18), center + Vector2(-34, 14), Color("241915", 0.7), 2.0)
	draw_line(center + Vector2(-6, 23), center + Vector2(-34, 24), Color("241915", 0.7), 2.0)
	draw_line(center + Vector2(6, 18), center + Vector2(34, 14), Color("241915", 0.7), 2.0)
	draw_line(center + Vector2(6, 23), center + Vector2(34, 24), Color("241915", 0.7), 2.0)

func _draw_tail(center: Vector2, sway: float, fur_color: Color) -> void:
	var base := center + Vector2(58, 18)
	var mid := base + Vector2(36, -42 + sway * 20.0)
	var tip := base + Vector2(54, -102 + sway * 38.0)

	draw_polyline(
		PackedVector2Array([base, mid, tip]),
		fur_color.darkened(0.08),
		18.0,
		true
	)
	draw_polyline(
		PackedVector2Array([base + Vector2(-2, -2), mid + Vector2(-2, -2), tip + Vector2(-2, -2)]),
		fur_color.lightened(0.05),
		10.0,
		true
	)

func _draw_status_marks(head_center: Vector2) -> void:
	var float_y := sin(animation_time * 2.4) * 4.0
	if active_request_type == &"FOOD":
		draw_circle(head_center + Vector2(-92, -54 + float_y), 16.0, Color("ffb454"))
		draw_circle(head_center + Vector2(-92, -54 + float_y), 7.0, Color("7a4a17"))
	elif active_request_type == &"ATTENTION":
		draw_circle(head_center + Vector2(92, -54 + float_y), 16.0, Color("ff7f7f"))
		draw_circle(head_center + Vector2(84, -55 + float_y), 6.5, Color("fff1f4"))
		draw_circle(head_center + Vector2(100, -55 + float_y), 6.5, Color("fff1f4"))
		draw_polygon(
			PackedVector2Array([
				head_center + Vector2(92, -40 + float_y),
				head_center + Vector2(79, -54 + float_y),
				head_center + Vector2(105, -54 + float_y),
			]),
			PackedColorArray([Color("fff1f4"), Color("fff1f4"), Color("fff1f4")])
		)

	if sleep_result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP:
		draw_arc(head_center + Vector2(0, -96), 18.0, 0.2, PI - 0.2, 16, Color("fff3b1"), 3.0)
		draw_arc(head_center + Vector2(30, -82), 10.0, 0.2, PI - 0.2, 14, Color("fff3b1", 0.8), 2.0)
	elif sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP:
		var anger_wave := sin(animation_time * 11.0) * 4.0
		draw_line(head_center + Vector2(-18, -112), head_center + Vector2(-2, -90 + anger_wave), Color("ff6d57"), 4.0)
		draw_line(head_center + Vector2(-2, -90 + anger_wave), head_center + Vector2(14, -114), Color("ff6d57"), 4.0)
		draw_line(head_center + Vector2(18, -104), head_center + Vector2(30, -126 + anger_wave * 0.5), Color("ff9c57"), 4.0)
		draw_line(head_center + Vector2(30, -126 + anger_wave * 0.5), head_center + Vector2(40, -100), Color("ff9c57"), 4.0)

func _fur_color() -> Color:
	var fur_color := Color("bd8857")
	if current_phase == TICK_SYSTEM.PHASE_EVENING:
		fur_color = Color("c08f63")
	elif current_phase == TICK_SYSTEM.PHASE_NIGHT:
		fur_color = Color("8c7b87")

	if mood == &"SATISFIED":
		fur_color = Color("d9a76a")
	elif mood == &"UPSET":
		fur_color = Color("8e6c5a")
	elif mood == &"FURIOUS":
		fur_color = Color("8c5a56")
	return fur_color

func _bob_amount() -> float:
	match mood:
		&"REQUESTING":
			return sin(animation_time * 4.2) * 6.0
		&"SATISFIED":
			return sin(animation_time * 3.1) * 3.5
		&"UPSET":
			return sin(animation_time * 5.0) * 2.0
		&"FURIOUS":
			return sin(animation_time * 12.0) * 3.8
		&"SLEEPING":
			return sin(animation_time * 1.3) * 2.5
		_:
			return sin(animation_time * 2.2) * 2.8

func _breath_amount() -> float:
	if mood == &"SLEEPING":
		return sin(animation_time * 1.2) * 1.4
	if mood == &"FURIOUS":
		return sin(animation_time * 10.0) * 0.4
	return sin(animation_time * 2.0) * 1.0

func _tail_sway() -> float:
	match mood:
		&"REQUESTING":
			return sin(animation_time * 5.2) * 1.0
		&"UPSET":
			return sin(animation_time * 7.0) * 1.15
		&"FURIOUS":
			return sin(animation_time * 13.0) * 1.6
		&"SLEEPING":
			return sin(animation_time * 0.9) * 0.2
		_:
			return sin(animation_time * 2.4) * 0.45

func _blink_amount() -> float:
	if mood == &"SLEEPING":
		return 1.0
	if mood == &"FURIOUS":
		return 0.0

	var cycle := fposmod(animation_time, 4.8)
	if cycle > 3.08 and cycle < 3.24:
		return 0.9
	if cycle > 3.32 and cycle < 3.46:
		return 1.0
	return 0.0

func _rage_shake() -> Vector2:
	if mood != &"FURIOUS":
		return Vector2.ZERO
	return Vector2(
		sin(animation_time * 19.0) * 3.4,
		cos(animation_time * 16.0) * 1.6
	)
