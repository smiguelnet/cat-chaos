extends Node2D

@onready var game_manager = $GameManager
@onready var ui_root = $UI
@onready var cat = $Cat
@onready var player = $Player
@onready var environment = $Environment

func _ready() -> void:
	ui_root.feed_requested.connect(game_manager.request_feed)
	ui_root.pet_requested.connect(game_manager.request_pet)
	player.feed_requested.connect(game_manager.request_feed)
	player.pet_requested.connect(game_manager.request_pet)

	game_manager.state_changed.connect(ui_root.apply_state)
	game_manager.state_changed.connect(cat.apply_state)
	game_manager.state_changed.connect(environment.apply_state)
	game_manager.state_changed.connect(player.apply_state)

	game_manager.phase_changed.connect(ui_root.on_phase_changed)
	game_manager.phase_changed.connect(cat.on_phase_changed)
	game_manager.phase_changed.connect(environment.on_phase_changed)
	game_manager.phase_changed.connect(player.on_phase_changed)

	game_manager.request_generated.connect(ui_root.on_request_generated)
	game_manager.request_generated.connect(cat.on_request_generated)

	game_manager.request_completed.connect(ui_root.on_request_completed)
	game_manager.request_completed.connect(cat.on_request_completed)

	game_manager.request_failed.connect(ui_root.on_request_failed)
	game_manager.request_failed.connect(cat.on_request_failed)
	game_manager.request_failed.connect(environment.on_request_failed)

	game_manager.sleep_evaluated.connect(ui_root.on_sleep_evaluated)
	game_manager.sleep_evaluated.connect(cat.on_sleep_evaluated)
	game_manager.sleep_evaluated.connect(environment.on_sleep_evaluated)

	var initial_state = game_manager.get_state_snapshot()
	ui_root.apply_state(initial_state)
	cat.apply_state(initial_state)
	environment.apply_state(initial_state)
	player.apply_state(initial_state)
