extends PanelContainer
class_name CatChaosRequestPanel

var title_label: Label
var countdown_label: Label
var feedback_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	add_child(content)

	title_label = Label.new()
	countdown_label = Label.new()
	feedback_label = Label.new()

	content.add_child(title_label)
	content.add_child(countdown_label)
	content.add_child(feedback_label)

	clear_request(false)

func show_request(request_type: StringName, time_remaining: int) -> void:
	visible = true
	title_label.visible = true
	countdown_label.visible = true
	title_label.text = "Request: %s" % _request_label(request_type)
	countdown_label.text = "Time Remaining: %ss" % time_remaining

func clear_request(preserve_feedback: bool = true) -> void:
	title_label.visible = false
	countdown_label.visible = false
	if not preserve_feedback:
		feedback_label.text = ""
		feedback_label.modulate = Color.WHITE

func set_feedback(text: String, color: Color = Color.WHITE) -> void:
	feedback_label.text = text
	feedback_label.modulate = color

func _request_label(request_type: StringName) -> String:
	if request_type == &"FOOD":
		return "Food"
	return "Attention"
