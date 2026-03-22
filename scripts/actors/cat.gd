extends Node2D
class_name CatPresentation

const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

const FRAME_SIZE := Vector2(128.0, 64.0)
const ROW_IDLE := 0
const ROW_RUN := 1
const ROW_JUMP := 2

const IDLE_FRAMES := [1, 2, 3, 4, 5, 6, 7]
const RUN_FRAMES := [1, 2, 3, 4, 5, 6, 7]
const JUMP_FRAMES := [1, 2, 3, 4, 5, 6, 7]
const SLEEP_FRAMES := [2, 3, 4, 5]

const BASE_SPRITE_POSITION := Vector2(0, -8)
const BASE_SPRITE_SCALE := Vector2(3.2, 3.2)
const MEOW_REPEAT_INTERVAL := 1.8

@onready var sprite: Sprite2D = $Sprite
@onready var meow_player: AudioStreamPlayer = $MeowPlayer

var current_phase: StringName = TICK_SYSTEM.PHASE_DAY
var mood: StringName = &"IDLE"
var active_request_type: StringName = &""
var sleep_result: StringName = &""
var animation_time: float = 0.0
var meow_cooldown: float = 0.0

func _ready() -> void:
	set_process(true)
	_update_visuals()
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	_update_meow_loop(delta)
	_update_visuals()
	queue_redraw()

func apply_state(state) -> void:
	current_phase = state.phase
	if state.active_request == null and current_phase != TICK_SYSTEM.PHASE_NIGHT and mood == &"REQUESTING":
		mood = &"IDLE"
	if current_phase == TICK_SYSTEM.PHASE_NIGHT:
		mood = &"FURIOUS" if sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	active_request_type = &"" if state.active_request == null else state.active_request["type"]
	if active_request_type == &"":
		meow_cooldown = 0.0
	_update_visuals()
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	if to_phase == TICK_SYSTEM.PHASE_DAY:
		mood = &"IDLE"
		sleep_result = &""
	elif to_phase == TICK_SYSTEM.PHASE_NIGHT:
		mood = &"SLEEPING"
		meow_cooldown = 0.0
		if meow_player != null and meow_player.playing:
			meow_player.stop()
	_update_visuals()
	queue_redraw()

func on_request_generated(request_type: StringName, _time_remaining: int) -> void:
	active_request_type = request_type
	mood = &"REQUESTING"
	meow_cooldown = 0.0
	_play_meow()
	_update_visuals()
	queue_redraw()

func on_request_completed(_request_type: StringName) -> void:
	active_request_type = &""
	mood = &"SATISFIED"
	meow_cooldown = 0.0
	if meow_player != null and meow_player.playing:
		meow_player.stop()
	_update_visuals()
	queue_redraw()

func on_request_failed(_request_type: StringName) -> void:
	active_request_type = &""
	mood = &"UPSET"
	meow_cooldown = 0.0
	if meow_player != null and meow_player.playing:
		meow_player.stop()
	_update_visuals()
	queue_redraw()

func on_sleep_evaluated(result: StringName, _state) -> void:
	sleep_result = result
	mood = &"FURIOUS" if result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	_update_visuals()
	queue_redraw()

func _update_visuals() -> void:
	if sprite == null:
		return

	var row := ROW_IDLE
	var frames = IDLE_FRAMES
	var fps := 4.0
	var sprite_modulate := Color.WHITE
	var sprite_position := BASE_SPRITE_POSITION
	var rotation := 0.0

	match mood:
		&"REQUESTING":
			row = ROW_RUN
			frames = RUN_FRAMES
			fps = 10.0
		&"SATISFIED":
			row = ROW_JUMP
			frames = JUMP_FRAMES
			fps = 8.0
		&"UPSET":
			row = ROW_RUN
			frames = RUN_FRAMES
			fps = 8.0
			sprite_modulate = Color("e9c89a")
		&"FURIOUS":
			row = ROW_JUMP
			frames = JUMP_FRAMES
			fps = 12.0
			sprite_modulate = Color("ffbf8f")
		&"SLEEPING":
			row = ROW_IDLE
			frames = SLEEP_FRAMES
			fps = 2.0
			sprite_position += Vector2(-10, 18)
			rotation = -0.18
			sprite_modulate = Color("d7d8ec")

	if current_phase == TICK_SYSTEM.PHASE_EVENING:
		sprite_modulate = sprite_modulate.darkened(0.06)
	elif current_phase == TICK_SYSTEM.PHASE_NIGHT and mood != &"SLEEPING":
		sprite_modulate = sprite_modulate.darkened(0.18)

	var frame_index := int(animation_time * fps) % frames.size()
	var atlas_frame: int = frames[frame_index]
	var bob := _bob_amount()
	var shake := _rage_shake()
	var scale_factor := 1.0 + _breath_amount() * 0.04

	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		Vector2(FRAME_SIZE.x * atlas_frame, FRAME_SIZE.y * row),
		FRAME_SIZE
	)
	sprite.position = sprite_position + Vector2(0, bob) + shake
	sprite.scale = BASE_SPRITE_SCALE * scale_factor
	sprite.rotation = rotation
	sprite.modulate = sprite_modulate
	sprite.flip_h = active_request_type == &"ATTENTION"

func _update_meow_loop(delta: float) -> void:
	if active_request_type == &"" or current_phase == TICK_SYSTEM.PHASE_NIGHT:
		return

	meow_cooldown -= delta
	if meow_cooldown <= 0.0:
		_play_meow()
		meow_cooldown = MEOW_REPEAT_INTERVAL

func _play_meow() -> void:
	if meow_player == null:
		return
	meow_player.stop()
	meow_player.play()

func _draw() -> void:
	var shadow_alpha := 0.16 if current_phase != TICK_SYSTEM.PHASE_NIGHT else 0.24
	var shadow_position := Vector2(0, 98)
	if mood == &"SLEEPING":
		shadow_position += Vector2(-4, 8)
	draw_set_transform(shadow_position, 0.0, Vector2(2.2, 0.38))
	draw_circle(Vector2.ZERO, 24.0, Color(0, 0, 0, shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_status_marks(_head_anchor())

func _draw_status_marks(head_center: Vector2) -> void:
	var float_y := sin(animation_time * 2.4) * 4.0
	if active_request_type == &"FOOD":
		draw_circle(head_center + Vector2(-70, -16 + float_y), 13.0, Color("ffb454"))
		draw_circle(head_center + Vector2(-70, -16 + float_y), 5.5, Color("7a4a17"))
	elif active_request_type == &"ATTENTION":
		draw_circle(head_center + Vector2(70, -16 + float_y), 13.0, Color("ff7f7f"))
		draw_circle(head_center + Vector2(64, -17 + float_y), 5.5, Color("fff1f4"))
		draw_circle(head_center + Vector2(76, -17 + float_y), 5.5, Color("fff1f4"))
		draw_polygon(
			PackedVector2Array([
				head_center + Vector2(70, -4 + float_y),
				head_center + Vector2(60, -16 + float_y),
				head_center + Vector2(80, -16 + float_y),
			]),
			PackedColorArray([Color("fff1f4"), Color("fff1f4"), Color("fff1f4")])
		)

	if sleep_result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP:
		draw_arc(head_center + Vector2(0, -64), 16.0, 0.2, PI - 0.2, 16, Color("fff3b1"), 3.0)
		draw_arc(head_center + Vector2(26, -52), 8.0, 0.2, PI - 0.2, 14, Color("fff3b1", 0.8), 2.0)
	elif sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP:
		var anger_wave := sin(animation_time * 11.0) * 4.0
		draw_line(head_center + Vector2(-14, -76), head_center + Vector2(-2, -58 + anger_wave), Color("ff6d57"), 4.0)
		draw_line(head_center + Vector2(-2, -58 + anger_wave), head_center + Vector2(12, -80), Color("ff6d57"), 4.0)
		draw_line(head_center + Vector2(14, -70), head_center + Vector2(24, -88 + anger_wave * 0.5), Color("ff9c57"), 4.0)
		draw_line(head_center + Vector2(24, -88 + anger_wave * 0.5), head_center + Vector2(32, -66), Color("ff9c57"), 4.0)

func _head_anchor() -> Vector2:
	var head_center := sprite.position + Vector2(0, -72)
	if mood == &"SLEEPING":
		head_center += Vector2(-8, 14)
	return head_center

func _bob_amount() -> float:
	match mood:
		&"REQUESTING":
			return sin(animation_time * 8.0) * 4.0
		&"SATISFIED":
			return sin(animation_time * 5.0) * 5.0
		&"UPSET":
			return sin(animation_time * 7.0) * 3.0
		&"FURIOUS":
			return sin(animation_time * 12.0) * 4.5
		&"SLEEPING":
			return sin(animation_time * 1.4) * 1.5
		_:
			return sin(animation_time * 2.0) * 1.5

func _breath_amount() -> float:
	if mood == &"SLEEPING":
		return sin(animation_time * 1.2) * 1.4
	if mood == &"FURIOUS":
		return sin(animation_time * 10.0) * 0.4
	return sin(animation_time * 2.0) * 1.0

func _rage_shake() -> Vector2:
	if mood != &"FURIOUS":
		return Vector2.ZERO
	return Vector2(
		sin(animation_time * 19.0) * 4.0,
		cos(animation_time * 16.0) * 1.8
	)
