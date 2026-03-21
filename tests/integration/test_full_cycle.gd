extends RefCounted
class_name TestFullCycle

const GAME_MANAGER_SCRIPT = preload("res://scripts/gameplay/game_manager.gd")
const TEST_CONFIG_RESOURCE = preload("res://data/test_configs/deterministic_test_config.tres")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")
const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const TEST_ASSERT = preload("res://tests/test_assert.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	var manager = GAME_MANAGER_SCRIPT.new()
	manager.config = TEST_CONFIG_RESOURCE.duplicate(true)
	manager.tick_autostart = false
	manager.initialize_game(1337)

	var generated_requests: Array[StringName] = []
	var sleep_results: Array[StringName] = []

	manager.request_generated.connect(func(request_type: StringName, _time_remaining: int) -> void:
		generated_requests.append(request_type)
	)
	manager.sleep_evaluated.connect(func(result: StringName, _state) -> void:
		sleep_results.append(result)
	)

	manager.simulate_ticks(manager.config.day_duration)

	for _tick in manager.config.evening_duration:
		if manager.state.active_request != null:
			if manager.state.active_request["type"] == &"FOOD":
				manager.request_feed()
			else:
				manager.request_pet()
		manager.tick_once()

	manager.simulate_ticks(manager.config.night_duration)

	failures.append_array(TEST_ASSERT.assert_eq(generated_requests.size(), 3, "full-cycle integration run should still generate exactly three evening requests"))
	failures.append_array(TEST_ASSERT.assert_eq(sleep_results.size(), 1, "sleep should be evaluated exactly once per cycle"))
	if sleep_results.size() == 1:
		failures.append_array(TEST_ASSERT.assert_in(sleep_results[0], [SLEEP_EVALUATOR.RESULT_GOOD_SLEEP, SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP], "sleep result should be one of the two canonical outcomes"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.phase, TICK_SYSTEM.PHASE_DAY, "integration run should end at the next day"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.cycle_index, 2, "integration run should advance the cycle index"))
	return failures
