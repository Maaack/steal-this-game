@tool
extends Node

@export var inventory_container_scene : PackedScene
@export var inventory_manager : InventoryManager
@export var inventory_grid : Container
@export var max_visible : int = 0

var inventory_map : Dictionary

func _add_inventory_container() -> Node:
	var instance = inventory_container_scene.instantiate()
	inventory_grid.add_child(instance)
	return instance

func _on_quantity_updated(quantity : ResourceQuantity):
	if not quantity.name in inventory_map:
		inventory_map[quantity.name] = _add_inventory_container()
	var container = inventory_map[quantity.name]
	container.resource_name = quantity.name
	container.icon = quantity.icon
	container.quantity = quantity.quantity

func _ready():
	inventory_manager.quantity_updated.connect(_on_quantity_updated)
