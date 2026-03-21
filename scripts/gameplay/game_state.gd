extends Resource
class_name GameState

@export var phase: StringName = &"DAY"
@export var phase_time_remaining: int = 10
@export var fullness: int = 80
@export var happiness: int = 80
@export var calmness: int = 60
@export var active_request: Variant = null
@export var cycle_index: int = 1
@export var rng_state: int = 0

func duplicate_state():
	var copy = get_script().new()
	copy.phase = phase
	copy.phase_time_remaining = phase_time_remaining
	copy.fullness = fullness
	copy.happiness = happiness
	copy.calmness = calmness
	copy.active_request = null if active_request == null else active_request.duplicate(true)
	copy.cycle_index = cycle_index
	copy.rng_state = rng_state
	return copy
