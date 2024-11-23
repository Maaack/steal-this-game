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
@export var knowledge_manager : KnowledgeManager
@export var action_container : Container
@export var event_view : EventView

func _ready():
	city_name = city_name
	city_actions = city_actions
	%CityContainer.action_done.connect(_on_action_done)
	for child in %ActionsContainer.get_children():
		if child.has_signal(&"action_done"):
			if child.action_done.is_connected(_on_action_done): continue
			child.action_done.connect(_on_location_action_done)
	action_container.child_entered_tree.connect(_on_child_entered_container)

func _on_action_done(action_type : Globals.ActionTypes, action_button : ActionButton):
	var event_string : String
	match action_type:
		Globals.ActionTypes.SCOUT:
			action_button.wait(5)
			var location_scouted = location_manager.scout()
			if location_scouted == null:
				event_string = "No new locations were discovered."
				event_view.add_event_text(event_string)
			else:
				event_string = "You scouted %s" % location_scouted.name
				event_view.add_event_text(event_string)
		Globals.ActionTypes.READ:
			action_button.wait(10)
			knowledge_manager.read()
			
func _on_location_action_done(action_data : ActionData, location_data : LocationData):
	var event_string : String
	event_view.add_event_text(action_data.try_message)
	for cost in action_data.resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			event_view.add_event_text("Not enough resources.")
			return
	for cost in action_data.resource_cost:
		inventory_manager.remove(cost.name, cost.quantity)
	
	for result in action_data.success_resource_result:
		inventory_manager.add(result.duplicate())
	for result in action_data.location_success_resource_result:
		location_data.resources.add(result.duplicate())

func _on_child_entered_container(node: Node):
	if node.has_signal(&"action_done"):
		node.action_done.connect(_on_location_action_done)
