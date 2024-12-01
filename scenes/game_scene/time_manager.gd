class_name TimeManager
extends Node

const SUSPICION_DECAY : float = 0.001
const FATIGUE_DECAY : float = 0.004

@export var location_manager : LocationManager
@export var action_containers : Array[Container]
@export var enabled : bool = true
@export_range(0, 16) var game_speed : float = 1.0
var _game_time_passed : float = 0 :
	get = get_game_time
var _real_time_passed : float = 0 :
	get = get_real_time

func get_game_time():
	return _game_time_passed

func get_real_time():
	return _real_time_passed

func  _process(delta):
	_real_time_passed += delta
	var _game_time_delta = delta * game_speed
	_game_time_passed += _game_time_delta
	if not enabled: return
	for location in location_manager.discovered_locations:
		for quantity in location.resources.contents:
			var decay : float
			match quantity.name:
				&"suspicion":
					decay = SUSPICION_DECAY * _game_time_delta
				&"fatigue":
					decay = FATIGUE_DECAY * _game_time_delta
			var decay_quantity = quantity.duplicate()
			var min_decay : float = min(decay, decay_quantity.quantity)
			decay_quantity.quantity = min_decay
			location.resources.remove(decay_quantity)
	for child in action_containers:
		if child.has_method("tick"):
			child.tick(_game_time_delta)
