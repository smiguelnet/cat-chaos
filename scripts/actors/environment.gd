extends Node2D
class_name EnvironmentPresentation

const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var disturbed_sleep_music: AudioStreamPlayer = $DisturbedSleepMusic

var current_phase: StringName = TICK_SYSTEM.PHASE_DAY
var last_sleep_result: StringName = &""
var request_failed_flash: bool = false

func _ready() -> void:
	if background_music != null:
		background_music.finished.connect(_on_background_music_finished)
	if disturbed_sleep_music != null:
		disturbed_sleep_music.finished.connect(_on_disturbed_sleep_music_finished)
	_update_music_state()
	_update_background_visuals()
	queue_redraw()

func apply_state(state) -> void:
	current_phase = state.phase
	if state.phase != TICK_SYSTEM.PHASE_EVENING:
		request_failed_flash = false
	_update_music_state()
	_update_background_visuals()
	queue_redraw()

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	current_phase = to_phase
	request_failed_flash = false
	if to_phase != TICK_SYSTEM.PHASE_NIGHT:
		last_sleep_result = &""
	_update_music_state()
	_update_background_visuals()
	queue_redraw()

func on_request_failed(_request_type: StringName) -> void:
	request_failed_flash = true
	queue_redraw()

func on_sleep_evaluated(result: StringName, _state) -> void:
	last_sleep_result = result
	request_failed_flash = false
	_update_music_state()
	queue_redraw()

func _on_background_music_finished() -> void:
	if _should_play_music():
		background_music.play()

func _on_disturbed_sleep_music_finished() -> void:
	if _should_play_disturbed_sleep_music():
		disturbed_sleep_music.play()

func _should_play_music() -> bool:
	return current_phase != TICK_SYSTEM.PHASE_NIGHT

func _should_play_disturbed_sleep_music() -> bool:
	return current_phase == TICK_SYSTEM.PHASE_NIGHT \
		and last_sleep_result == SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP

func _update_music_state() -> void:
	if background_music != null:
		if not _should_play_music():
			if background_music.playing:
				background_music.stop()
		else:
			background_music.volume_db = -8.5 if current_phase == TICK_SYSTEM.PHASE_EVENING else -6.5
			if not background_music.playing:
				background_music.play()

	if disturbed_sleep_music != null:
		if not _should_play_disturbed_sleep_music():
			if disturbed_sleep_music.playing:
				disturbed_sleep_music.stop()
		elif not disturbed_sleep_music.playing:
			disturbed_sleep_music.play()

func _fit_background_to_viewport() -> void:
	if background_sprite == null or background_sprite.texture == null:
		return

	var viewport_size := get_viewport_rect().size
	var texture_size := background_sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	background_sprite.position = Vector2.ZERO
	background_sprite.scale = Vector2(
		viewport_size.x / texture_size.x,
		viewport_size.y / texture_size.y
	)

func _update_background_visuals() -> void:
	if background_sprite == null:
		return

	_fit_background_to_viewport()

	match current_phase:
		TICK_SYSTEM.PHASE_DAY:
			background_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		TICK_SYSTEM.PHASE_EVENING:
			background_sprite.modulate = Color(0.92, 0.80, 0.72, 1.0)
		TICK_SYSTEM.PHASE_NIGHT:
			background_sprite.modulate = Color(0.54, 0.60, 0.78, 0.98)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var fallback_color := Color("f5dcae")
	var phase_overlay := Color(1, 1, 1, 0.0)

	match current_phase:
		TICK_SYSTEM.PHASE_DAY:
			fallback_color = Color("f5dcae")
			phase_overlay = Color(1.0, 0.98, 0.9, 0.08)
		TICK_SYSTEM.PHASE_EVENING:
			fallback_color = Color("d78f63")
			phase_overlay = Color(0.84, 0.58, 0.42, 0.16)
		TICK_SYSTEM.PHASE_NIGHT:
			fallback_color = Color("34435d")
			phase_overlay = Color(0.10, 0.16, 0.30, 0.34)

	if background_sprite == null or background_sprite.texture == null:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), fallback_color, true)

	draw_rect(Rect2(Vector2.ZERO, viewport_size), phase_overlay, true)

	if request_failed_flash:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1.0, 0.56, 0.56, 0.12), true)

	if current_phase == TICK_SYSTEM.PHASE_NIGHT:
		var overlay_color := Color(0.76, 0.94, 0.76, 0.16) if last_sleep_result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP else Color(0.94, 0.76, 0.76, 0.16)
		if last_sleep_result != &"":
			draw_rect(Rect2(Vector2.ZERO, viewport_size), overlay_color, true)
