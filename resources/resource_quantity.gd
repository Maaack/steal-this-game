extends Resource
class_name ResourceQuantity

enum NumericalUnitSetting{ CONTINUOUS, DISCRETE }
@export var numerical_unit : NumericalUnitSetting = NumericalUnitSetting.CONTINUOUS
@export var quantity = 1.0 :
	get = get_quantity,
	set = set_quantity
@export var resource_unit : ResourceUnit

var name : StringName :
	get:
		return resource_unit.name
	set(value):
		resource_unit.name = value

var icon : Texture :
	get:
		return resource_unit.icon
	set(value):
		resource_unit.icon = value

func _to_string():
	return "%s, %f" % [resource_unit.name, quantity]

func set_quantity(value:float):
	quantity = _discrete_unit_check(value)

func get_quantity():
	return quantity

func _discrete_unit_check(new_quantity : float):
	if new_quantity != null && numerical_unit == NumericalUnitSetting.DISCRETE:
		var lt_zero = new_quantity < 0
		new_quantity = floor(abs(new_quantity))
		if lt_zero:
			new_quantity *= -1
	return new_quantity

func add_quantity(value:float):
	if value == null or value == 0.0:
		return
	quantity += _discrete_unit_check(value)

func split(value:float) -> ResourceQuantity:
	if quantity <= 0 or value <= 0:
		push_warning("splitting only supports positive quantities.")
	var split_quantity = duplicate()
	if value == null or value == 0.0:
		split_quantity.quantity = 0
		return split_quantity
	value = min(value, quantity)
	add_quantity(-value)
	split_quantity.quantity = value
	return split_quantity

func copy_from(value: ResourceQuantity):
	if value == null:
		return
	quantity = value.quantity
	resource_unit = value.resource_unit

func add(value, conserve_quantities:bool=true):
	if not is_instance_valid(value):
		return
	if not value.has_method('set_quantity'):
		push_error("adding incompatible types ", str(value), " and ", str(self))
		return
	if value.name != resource_unit.name:
		push_error("adding incompatible quantities ", str(value), " and ", str(self))
		return
	add_quantity(value.quantity)
	if conserve_quantities:
		value.quantity = 0

func _init():
	if not resource_unit:
		resource_unit = ResourceUnit.new()
