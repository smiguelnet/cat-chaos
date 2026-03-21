extends RefCounted
class_name RequestSystem

const RNG_MOD := 2147483648
const RNG_MULT := 1103515245
const RNG_INC := 12345

static func next_rng_state(current_state: int) -> int:
	return posmod((current_state * RNG_MULT) + RNG_INC, RNG_MOD)

static func generate_request(current_state: int, request_types: Array[StringName], request_duration: int) -> Dictionary:
	var next_state := next_rng_state(current_state)
	var request_index := next_state % request_types.size()
	return {
		"rng_state": next_state,
		"request": {
			"type": request_types[request_index],
			"time_remaining": request_duration,
		},
	}
