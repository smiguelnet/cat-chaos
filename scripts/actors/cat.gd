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
const ALERT_REPEAT_INTERVAL := 3.4
const SNORE_REPEAT_INTERVAL := 2.0

@onready var sprite: Sprite2D = $Sprite
@onready var meow_player: AudioStreamPlayer = $MeowPlayer
@onready var alert_player: AudioStreamPlayer = $AlertPlayer
@onready var snore_player: AudioStreamPlayer = $SnorePlayer

var current_phase: StringName = TICK_SYSTEM.PHASE_DAY
var mood: StringName = &"IDLE"
var active_request_type: StringName = &""
var active_request_time_remaining: int = 0
var active_request_time_total: int = 0
var sleep_result: StringName = &""
var animation_time: float = 0.0
var meow_cooldown: float = 0.0
var alert_cooldown: float = 0.0
var snore_cooldown: float = 0.0

func _ready() -> void:
	set_process(true)
	if meow_player != null:
		meow_player.finished.connect(_on_meow_finished)
	_update_visuals()
	queue_redraw()

func _process(delta: float) -> void:
	animation_time += delta
	_update_meow_loop(delta)
	_update_alert_loop(delta)
	_update_snore_loop(delta)
	_update_visuals()
	queue_redraw()

func apply_state(state) -> void:
	current_phase = state.phase
	if state.active_request == null and current_phase != TICK_SYSTEM.PHASE_NIGHT and mood == &"REQUESTING":
		mood = &"IDLE"
	if current_phase == TICK_SYSTEM.PHASE_NIGHT:
		mood = &"FURIOUS" if sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	active_request_type = &"" if state.active_request == null else state.active_request["type"]
	if state.active_request == null:
		active_request_time_remaining = 0
		active_request_time_total = 0
		meow_cooldown = 0.0
		alert_cooldown = 0.0
	else:
		active_request_time_remaining = int(state.active_request["time_remaining"])
		if active_request_time_total <= 0:
			active_request_time_total = active_request_time_remaining
	if not _should_play_snore():
		snore_cooldown = 0.0
	_update_visuals()
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	if to_phase == TICK_SYSTEM.PHASE_DAY:
		mood = &"IDLE"
		sleep_result = &""
		snore_cooldown = 0.0
		if snore_player != null and snore_player.playing:
			snore_player.stop()
	elif to_phase == TICK_SYSTEM.PHASE_NIGHT:
		mood = &"SLEEPING"
		active_request_time_remaining = 0
		active_request_time_total = 0
		meow_cooldown = 0.0
		alert_cooldown = 0.0
		snore_cooldown = 0.0
		if meow_player != null and meow_player.playing:
			meow_player.stop()
		if alert_player != null and alert_player.playing:
			alert_player.stop()
		if snore_player != null and snore_player.playing:
			snore_player.stop()
	_update_visuals()
	queue_redraw()

func on_request_generated(request_type: StringName, _time_remaining: int) -> void:
	active_request_type = request_type
	active_request_time_remaining = _time_remaining
	active_request_time_total = _time_remaining
	mood = &"REQUESTING"
	meow_cooldown = 0.0
	alert_cooldown = 0.0
	_play_meow()
	_play_alert()
	_update_visuals()
	queue_redraw()

func on_request_completed(_request_type: StringName) -> void:
	active_request_type = &""
	active_request_time_remaining = 0
	active_request_time_total = 0
	mood = &"SATISFIED"
	meow_cooldown = 0.0
	alert_cooldown = 0.0
	if meow_player != null and meow_player.playing:
		meow_player.stop()
	if alert_player != null and alert_player.playing:
		alert_player.stop()
	if snore_player != null and snore_player.playing:
		snore_player.stop()
	_update_visuals()
	queue_redraw()

func on_request_failed(_request_type: StringName) -> void:
	active_request_type = &""
	active_request_time_remaining = 0
	active_request_time_total = 0
	mood = &"UPSET"
	meow_cooldown = 0.0
	alert_cooldown = 0.0
	if meow_player != null and meow_player.playing:
		meow_player.stop()
	if alert_player != null and alert_player.playing:
		alert_player.stop()
	if snore_player != null and snore_player.playing:
		snore_player.stop()
	_update_visuals()
	queue_redraw()

func on_sleep_evaluated(result: StringName, _state) -> void:
	sleep_result = result
	mood = &"FURIOUS" if result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP else &"SLEEPING"
	snore_cooldown = 0.0
	if _should_play_snore():
		_play_snore()
	else:
		if snore_player != null and snore_player.playing:
			snore_player.stop()
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

	if active_request_type != &"" and active_request_time_total > 0:
		var urgency := 1.0 - (float(active_request_time_remaining) / float(active_request_time_total))
		var red_tint_strength := 0.18 + urgency * 0.28
		sprite_modulate = sprite_modulate.lerp(Color(1.0, 0.58, 0.58, 1.0), red_tint_strength)

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
	if _should_play_furious_night_meow():
		if meow_player != null and not meow_player.playing:
			_play_meow()
		return

	if active_request_type == &"" or current_phase == TICK_SYSTEM.PHASE_NIGHT:
		return

	meow_cooldown -= delta
	if meow_cooldown <= 0.0:
		_play_meow()
		meow_cooldown = MEOW_REPEAT_INTERVAL

func _update_alert_loop(delta: float) -> void:
	if active_request_type == &"" or current_phase == TICK_SYSTEM.PHASE_NIGHT:
		return

	alert_cooldown -= delta
	if alert_cooldown <= 0.0:
		_play_alert()
		alert_cooldown = ALERT_REPEAT_INTERVAL

func _update_snore_loop(delta: float) -> void:
	if not _should_play_snore():
		if snore_player != null and snore_player.playing:
			snore_player.stop()
		return

	snore_cooldown -= delta
	if snore_cooldown <= 0.0:
		_play_snore()
		snore_cooldown = SNORE_REPEAT_INTERVAL

func _play_meow() -> void:
	if meow_player == null:
		return
	meow_player.stop()
	meow_player.play()

func _play_alert() -> void:
	if alert_player == null:
		return
	alert_player.stop()
	alert_player.play()

func _play_snore() -> void:
	if snore_player == null:
		return
	snore_player.stop()
	snore_player.play()

func _on_meow_finished() -> void:
	if _should_play_furious_night_meow():
		meow_player.play()

func _should_play_snore() -> bool:
	return current_phase == TICK_SYSTEM.PHASE_NIGHT \
		and mood == &"SLEEPING" \
		and sleep_result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP

func _should_play_furious_night_meow() -> bool:
	return current_phase == TICK_SYSTEM.PHASE_NIGHT \
		and mood == &"FURIOUS" \
		and sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP

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
