extends Node

const SUSPICION_DECAY : float = 0.00025
const FATIGUE_DECAY : float = 0.001

@export var location_manager : LocationManager
@export var action_containers : Array[Container]
@export var enabled : bool = true
@export_range(0, 16) var game_speed : float = 1.0

func  _process(delta):
	if not enabled: return
	for location in location_manager.discovered_locations:
		for quantity in location.resources.contents:
			var decay : float
			match quantity.name:
				&"suspicion":
					decay = SUSPICION_DECAY * delta * game_speed
				&"fatigue":
					decay = FATIGUE_DECAY * delta * game_speed
			var decay_quantity = quantity.duplicate()
			var min_decay : float = min(decay, decay_quantity.quantity)
			decay_quantity.quantity = min_decay
			location.resources.remove(decay_quantity)
	for child in action_containers:
		if child.has_method("tick"):
			child.tick(delta * game_speed)
