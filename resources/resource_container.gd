class_name ResourceContainer
extends Resource

const TOTAL_QUANTITY = 'TOTAL_QUANTITY'

@export var name : String
@export var contents : Array[ResourceQuantity] :
	set = set_contents

var quantities : Array = []
var total_quantity : ResourceQuantity

func _to_string():
	var to_string = "%s: [" % name
	for content in contents:
		to_string += str(content) + ","
	return to_string + "]"

func set_contents(value:Array):
	if value == null:
		return
	contents = _return_valid_array(value)
	update_quantities()

func _return_valid_array(array:Array):
	var final_array : Array = []
	for unit in array:
		if unit is ResourceUnit:
			final_array.append(unit.duplicate())
	return final_array

func _reset_quantities():
	if total_quantity == null:
		total_quantity = ResourceQuantity.new()
		total_quantity.name = TOTAL_QUANTITY
	total_quantity.quantity = 0
	for quantity in quantities:
		if quantity is ResourceQuantity:
			quantity.quantity = 0

func update_quantities():
	_reset_quantities()
	for content in contents:
		if content is ResourceQuantity:
			add_to_quantity(content)
			add_to_total(content)

func _get_quantity_to_add(content:ResourceQuantity):
	if content is ResourceQuantity:
		return content.quantity
	return 1

func add_to_quantity(content:ResourceQuantity):
	var quantity_to_add = _get_quantity_to_add(content)
	var quantity : ResourceQuantity
	quantity = find_quantity(content.name)
	if quantity:
		quantity.quantity += quantity_to_add
	else:
		quantity = ResourceQuantity.new()
		quantity.copy_from(content)
		quantity.quantity = quantity_to_add
		quantities.append(quantity)
	return quantity

func add_to_total(content:ResourceQuantity):
	var quantity_to_add = _get_quantity_to_add(content)
	total_quantity.quantity += quantity_to_add

func add_list(values):
	if values == null:
		return
	if not values is Array:
		values = [values]
	for value in values:
		add(value)
	return contents

func add(value:ResourceQuantity):
	if value == null:
		return
	if value is ResourceQuantity:
		var current_unit = find(value.name)
		if current_unit is ResourceQuantity:
			current_unit.quantity += value.quantity
		else:
			contents.append(value)
	else:
		contents.append(value)
	update_quantities()
	return contents

func remove_list(values):
	if values == null:
		return
	if not values is Array:
		values = [values]
	for value in values:
		remove(value)

func has(value:ResourceQuantity) -> bool:
	if value == null:
		return false
	if value is ResourceQuantity:
		var content = find(value.name)
		if content is ResourceQuantity:
			return content.quantity >= value.quantity
		else:
			return false
	else:
		return find(value.name) != null

func remove(value:ResourceQuantity):
	if value == null or not has(value):
		return
	if value is ResourceQuantity:
		var content = find(value.name)
		if content is ResourceQuantity:
			content.quantity -= value.quantity
	else:
		contents.erase(value)
	update_quantities()
	return value.duplicate()

func find_quantity(name_query:String) -> ResourceQuantity:
	for quantity in quantities:
		if quantity is ResourceQuantity and quantity.name == name_query:
			return quantity
	return

func find(name_query:String):
	for content in contents:
		if content is ResourceQuantity and content.name == name_query:
			return content
