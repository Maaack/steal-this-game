extends Node

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			city_container.city_name = city_name
@export var free_actions : Array[Globals.ActionTypes] :
	set(value):
		free_actions = value
		for action in free_actions:
			if action not in unlocked_actions:
				unlocked_actions.append(action)
@export var unlocked_actions : Array[Globals.ActionTypes]
@export var location_actions : Array[Globals.ActionTypes]

@export var inventory_manager : InventoryManager
@export var location_manager : LocationManager
@export var knowledge_manager : KnowledgeManager
@export var action_container : Container
@export var city_container : CityContainer
@export var event_view : EventView
@export var location_action_scene : PackedScene

var available_actions : Array[Globals.ActionTypes]
var action_node : Control
var detailed_action_type : Globals.ActionTypes
var selected_location_map : Dictionary[Globals.ActionTypes, LocationData]

func _ready():
	city_name = city_name
	available_actions = free_actions
	for action_type in available_actions:
		city_container.add_action(action_type)
	city_container.action_done.connect(_on_action_done)
	location_manager.location_discovered.connect(_on_location_discovered)
	knowledge_manager.action_learned.connect(_on_action_learned)

func _write_event(text : String):
	event_view.add_text(text)

func _write_failure(text : String):
	event_view.add_failure_text(text)

func _write_success(text : String):
	event_view.add_success_text(text)

func _write_discovered(text : String, type : String = ""):
	event_view.add_discovered_text(text, type)

func _clear_action_container():
	if action_node:
		action_node.queue_free()

func _add_location_action_scene() -> Node:
	_clear_action_container()
	action_node = location_action_scene.instantiate()
	action_container.add_child(action_node)
	return action_node

func _on_selected_location_changed(location_data : LocationData, action_type : Globals.ActionTypes):
	selected_location_map[action_type] = location_data

func _get_action_location(action_type : Globals.ActionTypes, wait_flag : bool = false) -> LocationData:
	if action_node == null or detailed_action_type != action_type:
		_add_location_action_scene()
		if action_node is LocationAction:
			action_node.action_type = action_type
			action_node.locations = location_manager.discovered_locations
			action_node.wait(wait_flag)
			if action_type in selected_location_map:
				action_node.selected_location = selected_location_map[action_type]
			action_node.selected_location_changed.connect(_on_selected_location_changed)
			detailed_action_type = action_type
			return null
	elif action_node is LocationAction:
		return action_node.selected_location
	return null

func _has_required_resources(resource_cost : Array[ResourceQuantity]) -> bool:
	var missing_resources : Array[String] = []
	for cost in resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			missing_resources.append("%.0f %s" % [cost.quantity, cost.name])
	if missing_resources.size() > 0:
		_write_failure("Requires %s." % Globals.get_comma_separated_list(missing_resources))
		return false
	return true

func _on_action_done(action_type : Globals.ActionTypes, action_button : ActionButton):
	# Match location actions
	if action_type in location_actions:
		var location_data : LocationData = _get_action_location(action_type, action_button.waiting)
		if location_data and not action_button.waiting:
			_on_location_action_done(action_type, location_data, action_button)
	if action_button.waiting: return
	match action_type:
		Globals.ActionTypes.LIBERATE:
			if not inventory_manager.has(&"food", 1000):
				_write_failure("Requires 1000 food.")
				return
			if not inventory_manager.has(&"reputation", 1000):
				_write_failure("Requires 1000 reputation.")
				return
			if not inventory_manager.has(&"energy", 100):
				_write_failure("Requires 100 energy.")
				return
			if not inventory_manager.has(&"determination", 100):
				_write_failure("Requires 100 determination.")
				return
			action_button.wait(60)
			await action_button.wait_time_passed
			_write_success("Liberated %s!" % city_name)
		Globals.ActionTypes.SCOUT:
			action_button.wait(5.0)
			await action_button.wait_time_passed
			var location_scouted = location_manager.scout()
			if location_scouted == null:
				_write_event("No new locations were discovered.")
			else:
				_write_discovered(location_scouted.name, "Location")
		Globals.ActionTypes.READ:
			_write_event("You try reading more secrets...")
			action_button.wait(10.0)
			await action_button.wait_time_passed
			_write_success("Read...")
			knowledge_manager.read()
		Globals.ActionTypes.EAT:
			if not inventory_manager.has(&"food", 1):
				_write_failure("Requires 1 food.")
				return
			action_button.wait(0.5)
			await action_button.wait_time_passed
			_write_success("Ate...")
			inventory_manager.remove_by_name(&"food", 1)
			inventory_manager.add_by_name(&"energy", 1)
		_:
			push_warning("No condition for action %s" % Globals.get_action_string(action_type))

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

func _on_location_action_done(action_type : Globals.ActionTypes, location_data : LocationData, action_button : ActionButton):
	var event_string : String
	var action_data = location_data.get_action(action_type)
	if not action_data:
		push_error("no action %s on %s" % [action_type, location_data.name])
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
	# Begin action
	action_button.wait(action_data.time_cost)
	if action_node.action_type == action_type and action_node.has_method(&"wait"):
		action_node.wait(true)
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
	if action_node.action_type == action_type and action_node.has_method(&"wait"):
		action_node.wait(false)

func _add_available_action(action_type : Globals.ActionTypes):
	if (action_type in available_actions) or \
		(action_type in location_actions and action_type not in location_manager.discovered_actions) or \
		(action_type not in unlocked_actions):
		return
	available_actions.append(action_type)
	city_container.add_action(action_type)

func _on_location_discovered(location : LocationData):
	if location == null: 
		push_warning("no location provided to discover")
		return
	for action in location.actions_available:
		_add_available_action(action.action)
	if action_node is LocationAction:
		action_node.locations = location_manager.discovered_locations
		action_node.update_locations()

func _unlock_action(action_type : Globals.ActionTypes):
	if action_type not in unlocked_actions:
		unlocked_actions.append(action_type)
		_write_discovered(Globals.get_action_string(action_type), "Action")
		_add_available_action(action_type)

func _on_action_learned(action_type : Globals.ActionTypes):
	_unlock_action(action_type)
