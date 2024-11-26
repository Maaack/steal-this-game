class_name ResourceBonusQuantity
extends ResourceQuantity

@export var multiplier : float = 1.0

func get_quantity():
	return quantity * multiplier

func get_raw_quantity():
	return super.get_quantity()
