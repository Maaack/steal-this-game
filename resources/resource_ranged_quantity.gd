class_name ResourceRandIQuantity
extends ResourceQuantity

@export var quantity_max : int
@export var quantity_min : int

func get_quantity():
	if quantity != 0:
		return quantity
	return randi_range(quantity_min, quantity_max)
