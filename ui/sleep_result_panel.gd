extends PanelContainer
class_name CatChaosSleepResultPanel

const SLEEP_EVALUATOR = preload("res://systems/sleep_evaluator.gd")

var result_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(280, 0)

	var content := VBoxContainer.new()
	add_child(content)

	result_label = Label.new()
	content.add_child(result_label)

	hide_result()

func show_result(result: StringName) -> void:
	visible = true
	result_label.text = "Sleep Result: %s" % result
	result_label.modulate = Color("b8ffd1") if result == SLEEP_EVALUATOR.RESULT_GOOD_SLEEP else Color("ffd0d0")

func hide_result() -> void:
	visible = false
	result_label.text = ""
