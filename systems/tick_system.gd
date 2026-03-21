extends RefCounted
class_name TickSystem

const PHASE_DAY := &"DAY"
const PHASE_EVENING := &"EVENING"
const PHASE_NIGHT := &"NIGHT"

const ACTION_FEED := &"FEED"
const ACTION_PET := &"PET"

static func can_accept_actions(phase: StringName) -> bool:
	return phase == PHASE_DAY or phase == PHASE_EVENING

static func clamp_stat(value: int) -> int:
	return clampi(value, 0, 100)

static func clamp_state(state: GameState) -> void:
	state.fullness = clamp_stat(state.fullness)
	state.happiness = clamp_stat(state.happiness)
	state.calmness = clamp_stat(state.calmness)

static func phase_duration(config: GameConfig, phase: StringName) -> int:
	match phase:
		PHASE_DAY:
			return config.day_duration
		PHASE_EVENING:
			return config.evening_duration
		PHASE_NIGHT:
			return config.night_duration
		_:
			return config.day_duration

static func next_phase(current_phase: StringName) -> StringName:
	match current_phase:
		PHASE_DAY:
			return PHASE_EVENING
		PHASE_EVENING:
			return PHASE_NIGHT
		_:
			return PHASE_DAY

static func apply_action(state: GameState, config: GameConfig, action: StringName) -> void:
	if action == ACTION_FEED:
		state.fullness += config.feed_amount
	elif action == ACTION_PET:
		state.happiness += config.pet_amount
	clamp_state(state)

static func apply_passive_rules(state: GameState, config: GameConfig) -> void:
	match state.phase:
		PHASE_DAY:
			state.fullness -= config.fullness_decay_per_tick
			state.happiness -= config.happiness_decay_per_tick
			state.calmness += config.calmness_gain_day_per_tick
		PHASE_EVENING:
			state.fullness -= config.fullness_decay_per_tick
			state.happiness -= config.happiness_decay_per_tick
		PHASE_NIGHT:
			pass
	clamp_state(state)

static func apply_request_failure_penalty(state: GameState, config: GameConfig) -> void:
	state.happiness -= config.request_fail_happiness_penalty
	state.calmness -= config.request_fail_calmness_penalty
	clamp_state(state)
