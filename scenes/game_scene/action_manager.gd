@tool
extends Node

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			%CityContainer.city_name = city_name
@export var city_actions : Array[Globals.ActionTypes] :
	set(value):
		city_actions = value
		if is_inside_tree():
			%CityContainer.city_actions = city_actions

@export var inventory_manager : InventoryManager

func _ready():
	city_name = city_name
	city_actions = city_actions
	%CityContainer.action_done.connect(_on_action_done)
	for child in %ActionsContainer.get_children():
		if child.has_signal(&"action_done"):
			if child.action_done.is_connected(_on_action_done): continue
			child.action_done.connect(_on_location_action_done)


func _on_action_done(action_type : Globals.ActionTypes):
	print("action done %s" % action_type)

func _on_location_action_done(action_data : ActionData):
	for cost in action_data.resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			print("Not enough resources.")
			return
		# TODO: Take resources
	for result in action_data.resource_result:
		inventory_manager.add(result.duplicate())
