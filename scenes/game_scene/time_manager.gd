extends Node

@export var location_manager : LocationManager
@export var enabled : bool = true

func  _process(delta):
	if not enabled: return
	for location in location_manager.city_locations:
		for quantity in location.resources.contents:
			match quantity.name:
				&"suspicion", &"fatigue":
					var decay_quantity = quantity.duplicate()
					var decay : float = 0.1 * delta
					var min_decay : float = min(decay, decay_quantity.quantity)
					decay_quantity.quantity = min_decay
					location.resources.remove(decay_quantity)
