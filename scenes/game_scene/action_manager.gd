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

func _write_event(text : String):
	event_view.add_text(text)

func _write_failure(text : String):
	event_view.add_failure_text(text)

func _write_success(text : String):
	event_view.add_success_text(text)

func _on_action_done(action_type : Globals.ActionTypes, action_button : ActionButton):
	match action_type:
		Globals.ActionTypes.SCOUT:
			action_button.wait(5.0)
			await action_button.wait_time_passed
			var location_scouted = location_manager.scout()
			if location_scouted == null:
				_write_event("No new locations were discovered.")
			else:
				_write_success("You scouted %s" % location_scouted.name)
		Globals.ActionTypes.READ:
			_write_event("You open your secret book to the next section.")
			action_button.wait(10.0)
			await action_button.wait_time_passed
			_write_success("You read...")
			knowledge_manager.read()
		Globals.ActionTypes.EAT:
			if not inventory_manager.has(&"food", 1):
				_write_failure("You are out of food.")
				return
			action_button.wait(0.5)
			await action_button.wait_time_passed
			_write_success("You eat...")
			inventory_manager.remove_by_name(&"food", 1)
			inventory_manager.add_by_name(&"energy", 1)

func _get_quantity_or_zero(quantity_name: StringName, quantities_map : Dictionary[StringName, float]) -> float:
	if quantity_name in quantities_map:
		return quantities_map[quantity_name]
	return 0.0

func _roll_against_quantity(quantity_name: StringName, quantities_map : Dictionary[StringName, float]) -> bool:
	return randf() > _get_quantity_or_zero(quantity_name, quantities_map)

func _get_action_success(action_data : ActionData, location_data : LocationData) -> bool:
	var resource_quantities : Dictionary[StringName, float]
	for quantity_data in location_data.resources.quantities:
		resource_quantities[quantity_data.name] = quantity_data.quantity
	match action_data.action:
		Globals.ActionTypes.STEAL:
			return _roll_against_quantity(&"suspicion", resource_quantities)
		Globals.ActionTypes.BEG:
			return _roll_against_quantity(&"fatigue", resource_quantities)
		_:
			return _roll_against_quantity(&"fatigue", resource_quantities) and _roll_against_quantity(&"suspicion", resource_quantities)
	return true

func _on_location_action_done(action_data : ActionData, location_data : LocationData, action_button : ActionButton):
	var event_string : String
	_write_event(action_data.try_message)
	var missing_resources : Array[String] = []
	for cost in action_data.resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			missing_resources.append("%.0f %s" % [cost.quantity, cost.name])
	if missing_resources.size() > 0:
		_write_failure("Requires %s." % Globals.get_comma_separated_list(missing_resources))
		return
	for cost in action_data.resource_cost:
		inventory_manager.remove(cost)
	action_button.wait(action_data.time_cost)
	await action_button.wait_time_passed
	if _get_action_success(action_data, location_data):
		if not action_data.success_message.is_empty():
			_write_success(action_data.success_message)
		for result in action_data.success_resource_result:
			inventory_manager.add(result.duplicate())
		for result in action_data.location_success_resource_result:
			location_data.resources.add(result.duplicate())
	else:
		if not action_data.failure_message.is_empty():
			_write_failure(action_data.failure_message)
		for result in action_data.failure_resource_result:
			inventory_manager.add(result.duplicate())
		for result in action_data.location_failure_resource_result:
			location_data.resources.add(result.duplicate())
func _on_child_entered_container(node: Node):
	if node.has_signal(&"action_done"):
		node.action_done.connect(_on_location_action_done)
