extends Node
class_name GameManager

const GAME_STATE_SCRIPT = preload("res://scripts/gameplay/game_state.gd")
const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const REQUEST_SYSTEM = preload("res://systems/request_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

signal tick_processed(state)
signal phase_changed(from_phase: StringName, to_phase: StringName)
signal request_generated(request_type: StringName, time_remaining: int)
signal request_completed(request_type: StringName)
signal request_failed(request_type: StringName)
signal sleep_evaluated(result: StringName, state)
signal state_changed(state)

@export var config: Resource
@export var tick_autostart: bool = true
@export var initial_seed: int = -1

var state
var pending_actions: Array[StringName] = []
var last_sleep_result: StringName = &""

@onready var tick_timer: Timer = %TickTimer

func _ready() -> void:
	if config == null:
		config = load("res://data/game_config.tres")
	initialize_game(initial_seed)
	tick_timer.wait_time = 1.0
	tick_timer.one_shot = false
	if tick_autostart:
		tick_timer.start()
	else:
		tick_timer.stop()

func _on_tick_timer_timeout() -> void:
	tick_once()

func initialize_game(seed: int = -1) -> void:
	if config == null:
		config = load("res://data/game_config.tres")
	var resolved_seed: int = seed if seed >= 0 else config.initial_seed
	state = GAME_STATE_SCRIPT.new()
	state.phase = TICK_SYSTEM.PHASE_DAY
	state.phase_time_remaining = config.day_duration
	state.fullness = config.initial_fullness
	state.happiness = config.initial_happiness
	state.calmness = config.initial_calmness
	state.active_request = null
	state.cycle_index = 1
	state.rng_state = resolved_seed
	pending_actions.clear()
	last_sleep_result = &""
	_emit_state_changed()

func get_state_snapshot():
	return state.duplicate_state()

func simulate_ticks(count: int) -> void:
	for _tick in count:
		tick_once()

func request_feed() -> void:
	_queue_action(TICK_SYSTEM.ACTION_FEED)

func request_pet() -> void:
	_queue_action(TICK_SYSTEM.ACTION_PET)

func tick_once() -> void:
	if state == null:
		initialize_game(initial_seed)

	_process_pending_actions()
	TICK_SYSTEM.apply_passive_rules(state, config)
	_update_active_request()
	state.phase_time_remaining -= 1

	var transitioned := false
	if state.phase_time_remaining <= 0:
		transitioned = true
		_transition_phase()

	_spawn_evening_request_if_needed(transitioned)
	TICK_SYSTEM.clamp_state(state)
	_emit_state_changed()
	tick_processed.emit(get_state_snapshot())

func _queue_action(action: StringName) -> void:
	if state == null or not TICK_SYSTEM.can_accept_actions(state.phase):
		return
	pending_actions.append(action)

func _process_pending_actions() -> void:
	if not TICK_SYSTEM.can_accept_actions(state.phase):
		pending_actions.clear()
		return

	for action in pending_actions:
		TICK_SYSTEM.apply_action(state, config, action)
		if state.active_request == null:
			continue
		if _action_matches_request(action, state.active_request["type"]):
			var completed_type: StringName = state.active_request["type"]
			state.active_request = null
			request_completed.emit(completed_type)
	pending_actions.clear()

func _update_active_request() -> void:
	if state.active_request == null:
		return

	state.active_request["time_remaining"] -= 1
	if state.active_request["time_remaining"] <= 0:
		var failed_type: StringName = state.active_request["type"]
		state.active_request = null
		TICK_SYSTEM.apply_request_failure_penalty(state, config)
		request_failed.emit(failed_type)

func _transition_phase() -> void:
	var from_phase: StringName = state.phase
	var to_phase: StringName = TICK_SYSTEM.next_phase(from_phase)

	state.phase = to_phase
	state.phase_time_remaining = TICK_SYSTEM.phase_duration(config, to_phase)

	match to_phase:
		TICK_SYSTEM.PHASE_DAY:
			state.active_request = null
			state.cycle_index += 1
		TICK_SYSTEM.PHASE_EVENING:
			state.active_request = null
		TICK_SYSTEM.PHASE_NIGHT:
			state.active_request = null
			last_sleep_result = SLEEP_EVALUATOR.evaluate_sleep(state, config)
			sleep_evaluated.emit(last_sleep_result, get_state_snapshot())

	phase_changed.emit(from_phase, to_phase)

func _spawn_evening_request_if_needed(transitioned: bool) -> void:
	if state.phase != TICK_SYSTEM.PHASE_EVENING:
		return

	var is_evening_start: bool = transitioned and state.phase_time_remaining == config.evening_duration
	var is_window_boundary: bool = not transitioned \
	and state.phase_time_remaining > 0 \
	and state.phase_time_remaining % config.request_window_duration == 0

	if not is_evening_start and not is_window_boundary:
		return

	var request_payload: Dictionary = REQUEST_SYSTEM.generate_request(
		state.rng_state,
		config.request_types,
		config.request_window_duration
	)
	state.rng_state = request_payload["rng_state"]
	state.active_request = request_payload["request"]
	request_generated.emit(state.active_request["type"], state.active_request["time_remaining"])

func _action_matches_request(action: StringName, request_type: StringName) -> bool:
	return (action == TICK_SYSTEM.ACTION_FEED and request_type == &"FOOD") \
		or (action == TICK_SYSTEM.ACTION_PET and request_type == &"ATTENTION")

func _emit_state_changed() -> void:
	state_changed.emit(get_state_snapshot())
