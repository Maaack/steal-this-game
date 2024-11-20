class_name InventoryManager
extends Node

signal inventory_updated
signal quantity_updated(quantity:ResourceQuantity)

@export var starting_inventory : Array[ResourceQuantity]

var inventory : ResourceContainer

func _fill_starting_inventory():
	inventory.add_list(starting_inventory)
	inventory_updated.emit()
	for quantity in starting_inventory:
		quantity_updated.emit(quantity)

func _ready():
	inventory = ResourceContainer.new()
	_fill_starting_inventory.call_deferred()

func add(item : ResourceQuantity):
	if item == null:
		return
	inventory.add(item)
	var quantity = inventory.find_quantity(item.name)
	inventory_updated.emit()
	quantity_updated.emit(quantity)

func remove_quantity(content:ResourceQuantity):
	if content == null:
		return
	inventory.remove(content)
	inventory_updated.emit()

func remove(quantity_name : String, quantity_amount : float):
	var quantity := ResourceQuantity.new()
	quantity.name = quantity_name
	quantity.quantity = quantity_amount
	remove_quantity(quantity)

func find(content:ResourceQuantity):
	if content == null:
		return
	return inventory.find(content.name)

func has(quantity_name : String, quantity_minimum : float) -> bool:
	var quantity := ResourceQuantity.new()
	quantity.name = quantity_name
	quantity.quantity = quantity_minimum
	return inventory.has(quantity)

func remove_all(quantity_name : String = "", content : ResourceUnit = null):
	if quantity_name.is_empty() and content:
		quantity_name = content.name
	if quantity_name.is_empty():
		return
	var quantity = inventory.find_quantity(quantity_name)
	if quantity == null:
		return
	inventory.remove(quantity.duplicate())
