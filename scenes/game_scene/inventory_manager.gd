class_name InventoryManager
extends Node

signal inventory_updated
signal quantity_updated(quantity:ResourceQuantity)

@export var starting_inventory : Array[ResourceQuantity]

var inventory : ResourceContainer

func _ready():
	inventory = ResourceContainer.new()
	inventory.add_contents(starting_inventory)

func add(item : ResourceQuantity):
	if item == null:
		return
	inventory.add_content(item)
	var quantity = inventory.find_quantity(item.name)
	inventory_updated.emit()
	quantity_updated.emit(quantity)

func remove_quantity(content:ResourceQuantity):
	if content == null:
		return
	inventory.remove_content(content)
	inventory_updated.emit()

func remove(quantity_name : String, quantity_amount : float):
	var quantity := ResourceQuantity.new()
	quantity.name = quantity_name
	quantity.quantity = quantity_amount
	remove_quantity(quantity)

func find(content:ResourceQuantity):
	if content == null:
		return
	return inventory.find_content(content.name)

func has(quantity_name : String, quantity_minimum : float) -> bool:
	var quantity := ResourceQuantity.new()
	quantity.name = quantity_name
	quantity.quantity = quantity_minimum
	return inventory.has_content(quantity)

func remove_all(quantity_name : String = "", content : ResourceUnit = null):
	if quantity_name.is_empty() and content:
		quantity_name = content.name
	if quantity_name.is_empty():
		return
	var quantity = inventory.find_quantity(quantity_name)
	if quantity == null:
		return
	inventory.remove_content(quantity.duplicate())
