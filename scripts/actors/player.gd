extends Node
class_name CatChaosPlayer

const TICK_SYSTEM = preload("res://systems/tick_system.gd")

signal feed_requested
signal pet_requested

var actions_enabled: bool = true

func _unhandled_input(event: InputEvent) -> void:
	if not actions_enabled:
		return

	if event.is_action_pressed("feed"):
		feed_requested.emit()
	elif event.is_action_pressed("pet"):
		pet_requested.emit()

func apply_state(state) -> void:
	actions_enabled = TICK_SYSTEM.can_accept_actions(state.phase)

func on_phase_changed(_from_phase: StringName, to_phase: StringName) -> void:
	actions_enabled = TICK_SYSTEM.can_accept_actions(to_phase)
