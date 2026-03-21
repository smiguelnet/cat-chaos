extends Resource
class_name GameConfig

@export var day_duration: int = 10
@export var evening_duration: int = 15
@export var night_duration: int = 5
@export var request_window_duration: int = 5

@export var initial_fullness: int = 80
@export var initial_happiness: int = 80
@export var initial_calmness: int = 60
@export var initial_seed: int = 1337

@export var fullness_decay_per_tick: int = 1
@export var happiness_decay_per_tick: int = 1
@export var calmness_gain_day_per_tick: int = 2

@export var feed_amount: int = 20
@export var pet_amount: int = 20

@export var request_fail_happiness_penalty: int = 10
@export var request_fail_calmness_penalty: int = 10
@export var sleep_threshold: int = 70

@export var request_types: Array[StringName] = [&"FOOD", &"ATTENTION"]
