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
@export var location_manager : LocationManager
@export var action_container : Container

func _ready():
	city_name = city_name
	city_actions = city_actions
	%CityContainer.action_done.connect(_on_action_done)
	for child in %ActionsContainer.get_children():
		if child.has_signal(&"action_done"):
			if child.action_done.is_connected(_on_action_done): continue
			child.action_done.connect(_on_location_action_done)
	action_container.child_entered_tree.connect(_on_child_entered_container)

func _on_action_done(action_type : Globals.ActionTypes):
	match action_type:
		Globals.ActionTypes.SCOUT:
			location_manager.scout()
	print("action done %s" % action_type)

func _on_location_action_done(action_data : ActionData):
	for cost in action_data.resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			print("Not enough resources.")
			return
		# TODO: Take resources
	for result in action_data.resource_result:
		inventory_manager.add(result.duplicate())

func _on_child_entered_container(node: Node):
	if node.has_signal(&"action_done"):
		node.action_done.connect(_on_location_action_done)
