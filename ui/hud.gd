extends PanelContainer
class_name CatChaosHud

var phase_label: Label
var timer_label: Label
var fullness_label: Label
var happiness_label: Label
var calmness_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(260, 0)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	phase_label = Label.new()
	timer_label = Label.new()
	fullness_label = Label.new()
	happiness_label = Label.new()
	calmness_label = Label.new()

	content.add_child(phase_label)
	content.add_child(timer_label)
	content.add_child(fullness_label)
	content.add_child(happiness_label)
	content.add_child(calmness_label)

func apply_state(state) -> void:
	phase_label.text = "Phase: %s" % state.phase
	timer_label.text = "Phase Timer: %ss" % state.phase_time_remaining
	fullness_label.text = "Fullness: %s" % state.fullness
	happiness_label.text = "Happiness: %s" % state.happiness
	calmness_label.text = "Calmness: %s" % state.calmness
