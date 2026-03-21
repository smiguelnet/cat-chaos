extends RefCounted
class_name SleepEvaluator

const RESULT_GOOD_SLEEP := &"Good Sleep"
const RESULT_DISTURBED_SLEEP := &"Disturbed Sleep"

static func evaluate_sleep(state, config) -> StringName:
	if state.fullness >= config.sleep_threshold \
	and state.happiness >= config.sleep_threshold \
	and state.calmness >= config.sleep_threshold:
		return RESULT_GOOD_SLEEP
	return RESULT_DISTURBED_SLEEP
