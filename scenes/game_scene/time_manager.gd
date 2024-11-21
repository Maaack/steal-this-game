extends Node

const SUSPICION_DECAY : float = 0.001

@export var location_manager : LocationManager
@export var actions_container : Container
@export var enabled : bool = true
@export_range(0, 16) var game_speed : float = 1.0

func  _process(delta):
	if not enabled: return
	for location in location_manager.city_locations:
		for quantity in location.resources.contents:
			match quantity.name:
				&"suspicion", &"fatigue":
					var decay_quantity = quantity.duplicate()
					var decay : float = SUSPICION_DECAY * delta * game_speed
					var min_decay : float = min(decay, decay_quantity.quantity)
					decay_quantity.quantity = min_decay
					location.resources.remove(decay_quantity)
	for child in actions_container.get_children():
		if child.has_method("tick"):
			child.tick(delta * game_speed)
