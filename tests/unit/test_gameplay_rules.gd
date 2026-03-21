extends RefCounted
class_name TestGameplayRules

const GAME_MANAGER_SCRIPT = preload("res://scripts/gameplay/game_manager.gd")
const GAME_CONFIG_RESOURCE = preload("res://data/game_config.tres")
const TEST_CONFIG_RESOURCE = preload("res://data/test_configs/deterministic_test_config.tres")
const GAME_STATE_SCRIPT = preload("res://scripts/gameplay/game_state.gd")
const TICK_SYSTEM = preload("res://systems/tick_system.gd")
const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")
const TEST_ASSERT = preload("res://tests/test_assert.gd")

func run() -> Array[String]:
	var failures: Array[String] = []
	failures.append_array(_test_sleep_thresholds())
	failures.append_array(_test_request_generation_count())
	failures.append_array(_test_food_completion_and_reward())
	failures.append_array(_test_attention_completion_and_reward())
	failures.append_array(_test_request_failure_penalty())
	failures.append_array(_test_stat_bounds())
	failures.append_array(_test_deterministic_request_generation())
	failures.append_array(_test_tick_update_order())
	failures.append_array(_test_phase_transitions_and_cycle_index())
	return failures

func _create_manager(seed: int = 4242):
	var manager = GAME_MANAGER_SCRIPT.new()
	manager.config = TEST_CONFIG_RESOURCE.duplicate(true)
	manager.tick_autostart = false
	manager.initialize_game(seed)
	return manager

func _test_sleep_thresholds() -> Array[String]:
	var failures: Array[String] = []
	var good_state = GAME_STATE_SCRIPT.new()
	good_state.fullness = 70
	good_state.happiness = 70
	good_state.calmness = 70
	failures.append_array(TEST_ASSERT.assert_eq(
		SLEEP_EVALUATOR.evaluate_sleep(good_state, GAME_CONFIG_RESOURCE),
		SLEEP_EVALUATOR.RESULT_GOOD_SLEEP,
		"sleep evaluator should accept exact threshold values"
	))

	var disturbed_state = good_state.duplicate_state()
	disturbed_state.calmness = 69
	failures.append_array(TEST_ASSERT.assert_eq(
		SLEEP_EVALUATOR.evaluate_sleep(disturbed_state, GAME_CONFIG_RESOURCE),
		SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP,
		"sleep evaluator should fail when one stat is below threshold"
	))
	return failures

func _test_request_generation_count() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()
	var generated: Array[StringName] = []
	manager.request_generated.connect(func(request_type: StringName, _time_remaining: int) -> void:
		generated.append(request_type)
	)

	manager.simulate_ticks(manager.config.day_duration + manager.config.evening_duration)
	failures.append_array(TEST_ASSERT.assert_eq(generated.size(), 3, "one evening should generate exactly three requests"))
	return failures

func _test_food_completion_and_reward() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()
	var completed: Array[StringName] = []
	manager.request_completed.connect(func(request_type: StringName) -> void:
		completed.append(request_type)
	)

	manager.state.phase = TICK_SYSTEM.PHASE_EVENING
	manager.state.phase_time_remaining = 10
	manager.state.fullness = 50
	manager.state.active_request = {"type": &"FOOD", "time_remaining": 5}
	manager.request_feed()
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.active_request, null, "feed should complete an active food request"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.fullness, 69, "feed should apply its normal gain exactly once before evening decay"))
	failures.append_array(TEST_ASSERT.assert_eq(completed.size(), 1, "food completion should emit exactly one completion event"))
	return failures

func _test_attention_completion_and_reward() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()

	manager.state.phase = TICK_SYSTEM.PHASE_EVENING
	manager.state.phase_time_remaining = 10
	manager.state.happiness = 40
	manager.state.active_request = {"type": &"ATTENTION", "time_remaining": 5}
	manager.request_pet()
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.active_request, null, "pet should complete an active attention request"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.happiness, 59, "pet should apply its normal gain exactly once before evening decay"))
	return failures

func _test_request_failure_penalty() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()
	var failed: Array[StringName] = []
	manager.request_failed.connect(func(request_type: StringName) -> void:
		failed.append(request_type)
	)

	manager.state.phase = TICK_SYSTEM.PHASE_EVENING
	manager.state.phase_time_remaining = 10
	manager.state.fullness = 50
	manager.state.happiness = 50
	manager.state.calmness = 50
	manager.state.active_request = {"type": &"FOOD", "time_remaining": 1}
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.happiness, 39, "failed request should reduce happiness by 10 after passive decay"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.calmness, 40, "failed request should reduce calmness by 10"))
	failures.append_array(TEST_ASSERT.assert_eq(failed.size(), 1, "failed request should emit a single failure event"))
	return failures

func _test_stat_bounds() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()

	manager.state.phase = TICK_SYSTEM.PHASE_DAY
	manager.state.phase_time_remaining = 10
	manager.state.fullness = 95
	manager.state.happiness = 95
	manager.state.calmness = 99
	manager.request_feed()
	manager.request_pet()
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_true(manager.state.fullness <= 100, "fullness should stay clamped at or below 100"))
	failures.append_array(TEST_ASSERT.assert_true(manager.state.happiness <= 100, "happiness should stay clamped at or below 100"))
	failures.append_array(TEST_ASSERT.assert_true(manager.state.calmness <= 100, "calmness should stay clamped at or below 100"))

	manager.state.phase = TICK_SYSTEM.PHASE_EVENING
	manager.state.phase_time_remaining = 5
	manager.state.fullness = 0
	manager.state.happiness = 0
	manager.state.calmness = 0
	manager.state.active_request = {"type": &"ATTENTION", "time_remaining": 1}
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.fullness, 0, "fullness should not go below 0"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.happiness, 0, "happiness should not go below 0"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.calmness, 0, "calmness should not go below 0"))
	return failures

func _test_deterministic_request_generation() -> Array[String]:
	var failures: Array[String] = []
	var manager_a = _create_manager(777)
	var manager_b = _create_manager(777)
	var generated_a: Array[StringName] = []
	var generated_b: Array[StringName] = []

	manager_a.request_generated.connect(func(request_type: StringName, _time_remaining: int) -> void:
		generated_a.append(request_type)
	)
	manager_b.request_generated.connect(func(request_type: StringName, _time_remaining: int) -> void:
		generated_b.append(request_type)
	)

	manager_a.simulate_ticks(manager_a.config.day_duration + manager_a.config.evening_duration)
	manager_b.simulate_ticks(manager_b.config.day_duration + manager_b.config.evening_duration)

	failures.append_array(TEST_ASSERT.assert_eq(generated_a, generated_b, "request generation should be deterministic for a fixed seed"))
	failures.append_array(TEST_ASSERT.assert_eq(manager_a.state.rng_state, manager_b.state.rng_state, "rng state should match for identical runs"))
	return failures

func _test_tick_update_order() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()

	manager.state.phase = TICK_SYSTEM.PHASE_EVENING
	manager.state.phase_time_remaining = 1
	manager.state.fullness = 60
	manager.state.happiness = 60
	manager.state.calmness = 60
	manager.state.active_request = {"type": &"FOOD", "time_remaining": 1}
	manager.request_feed()
	manager.tick_once()

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.phase, TICK_SYSTEM.PHASE_NIGHT, "phase should transition after request processing and timer decrement"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.active_request, null, "matching action should clear the request before timeout processing"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.fullness, 79, "fullness should reflect action gain before passive evening decay"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.happiness, 59, "happiness should only reflect passive evening decay in this scenario"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.last_sleep_result, SLEEP_EVALUATOR.RESULT_DISTURBED_SLEEP, "sleep evaluation should happen when night begins"))
	return failures

func _test_phase_transitions_and_cycle_index() -> Array[String]:
	var failures: Array[String] = []
	var manager = _create_manager()

	manager.simulate_ticks(manager.config.day_duration + manager.config.evening_duration + manager.config.night_duration)

	failures.append_array(TEST_ASSERT.assert_eq(manager.state.phase, TICK_SYSTEM.PHASE_DAY, "full cycle should return to day"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.phase_time_remaining, manager.config.day_duration, "entering day should reset the day timer"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.cycle_index, 2, "returning to day should increment cycle index"))
	failures.append_array(TEST_ASSERT.assert_eq(manager.state.active_request, null, "active request should be cleared on new day"))
	return failures
