extends SceneTree

const SUITES := [
	preload("res://tests/unit/test_gameplay_rules.gd"),
	preload("res://tests/integration/test_full_cycle.gd"),
]

func _init() -> void:
	var failures: Array[String] = []

	for suite_script in SUITES:
		var suite = suite_script.new()
		failures.append_array(suite.run())

	if failures.is_empty():
		print("All tests passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
		print(failure)
	quit(1)
