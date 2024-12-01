class_name ActionManager
extends Node

signal city_liberated

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			city_container.city_name = city_name
			knowledge_manager.city_name = city_name
@export var available_actions : Array[Globals.ActionTypes] :
	set(value):
		available_actions = value
		for action in available_actions:
			if action not in discovered_actions:
				discovered_actions.append(action)
@export var discovered_actions : Array[Globals.ActionTypes]
@export var location_based_actions : Array[Globals.ActionTypes]

@export var inventory_manager : InventoryManager
@export var location_manager : LocationManager
@export var knowledge_manager : KnowledgeManager
@export var action_container : Control
@export var city_container : CityContainer
@export var event_view : EventView
@export var location_action_scene : PackedScene

var enabled : bool = false

var discovered_location_actions : Array[Globals.LocationAction]
var action_node : Control
var detailed_action_type : Globals.ActionTypes
var selected_location_map : Dictionary[Globals.ActionTypes, LocationData]
var bonuses : Array[Globals.Bonus]
var resource_bonuses : Array[Globals.ResourceBonus]
var action_resource_bonuses : Array[Globals.ActionResourceBonus]
var location_action_resource_bonuses : Array[Globals.LocationActionResourceBonus]
var selected_location_action_button : ActionButton

func _ready():
	city_name = city_name
	available_actions = available_actions
	for action_type in available_actions:
		city_container.add_action(action_type)
	city_container.action_done.connect(_on_action_done)
	location_manager.location_discovered.connect(_on_location_discovered)
	knowledge_manager.action_learned.connect(_on_action_learned)
	knowledge_manager.location_action_learned.connect(_on_location_action_learned)
	knowledge_manager.bonus_gained.connect(_on_bonus_gained)

func enter_city():
	enabled = true
	_write_event("You arrive in %s with some money, snacks, and a book of secrets." % city_name)
	await get_tree().create_timer(2, false).timeout
	_write_event("Luckily, you know a friend with a couch.")
	location_manager.fill_starting_locations()

#region writing stuff
func _write_event(text : String):
	event_view.add_text(text)

func _write_failure(text : String):
	event_view.add_failure_text(text)

func _write_success(text : String):
	event_view.add_success_text(text)

func _write_discovered(text : String, type : String = "", is_new : bool = true):
	event_view.add_discovered_text(text, type, is_new)

func _write_bonus(bonus : Globals.ResourceBonus):
	var text : String
	if bonus is Globals.LocationActionResourceBonus:
		text = "%s %s at %s" % [Globals.get_action_string(bonus.action_type), bonus.resource_name.capitalize(), Globals.get_location_string(bonus.location_type)]
	elif bonus is Globals.ActionResourceBonus:
		text = "%s %s" % [Globals.get_action_string(bonus.action_type), bonus.resource_name.capitalize()]
	else:
		text = "%s" % bonus.resource_name.capitalize()
	event_view.add_bonus_text(text, bonus.bonus)

func _write_quantity(quantity: ResourceQuantity):
	event_view.add_quantity_text(quantity, true)
#endregion

#region location container
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
		if action_node is LocationActionBox:
			action_node.action_type = action_type
			action_node.locations = location_manager.discovered_locations
			action_node.actionable_location_types = _get_location_types_by_action(action_type)
			action_node.wait(wait_flag)
			if action_type in selected_location_map:
				action_node.selected_location = selected_location_map[action_type]
			action_node.selected_location_changed.connect(_on_selected_location_changed)
			detailed_action_type = action_type
			return null
	elif action_node is LocationActionBox:
		return action_node.selected_location
	return null
#endregion

#region action processing
func _has_required_resources(resource_cost : Array[ResourceQuantity]) -> bool:
	var missing_resources : Array[String] = []
	for cost in resource_cost:
		if not inventory_manager.has(cost.name, cost.quantity):
			missing_resources.append("%.0f %s" % [cost.quantity, cost.name])
	if missing_resources.size() > 0:
		_write_failure("Requires %s." % Globals.get_comma_separated_list(missing_resources))
		return false
	return true

func _get_location_action_resource_bonus(resource_name: StringName, action_type : Globals.ActionTypes, location_type : Globals.LocationTypes) -> float:
	var multiplier : float = 1.0
	for bonus in location_action_resource_bonuses:
		if bonus is Globals.LocationActionResourceBonus:
			if bonus.resource_name == resource_name and \
			bonus.action_type == action_type and \
			bonus.location_type == location_type:
				multiplier *= bonus.get_multiplier()
	return multiplier
	
func _get_action_resource_bonus(resource_name: StringName, action_type : Globals.ActionTypes) -> float:
	var multiplier : float = 1.0
	for bonus in action_resource_bonuses:
		if bonus is Globals.ActionResourceBonus:
			if bonus.resource_name == resource_name and \
			bonus.action_type == action_type:
				multiplier *= bonus.get_multiplier()
	return multiplier
	
func _get_resource_bonus(resource_name: StringName) -> float:
	var multiplier : float = 1.0
	for bonus in resource_bonuses:
		if bonus is Globals.ResourceBonus:
			if bonus.resource_name == resource_name:
				multiplier *= bonus.get_multiplier()

	return multiplier

func _get_total_bonus(resource_name: StringName, action_type : Globals.ActionTypes = Globals.ActionTypes.NONE, location_type : Globals.LocationTypes = Globals.LocationTypes.NONE) -> float:
	var multiplier : float = 1.0
	if location_type != Globals.LocationTypes.NONE and action_type != Globals.ActionTypes.NONE:
		multiplier *= _get_location_action_resource_bonus(resource_name, action_type, location_type)
	if action_type != Globals.ActionTypes.NONE:
		multiplier *= _get_action_resource_bonus(resource_name, action_type)
	multiplier *= _get_resource_bonus(resource_name)
	return multiplier

func _get_quantity_with_bonus(quantity : ResourceQuantity, action_type : Globals.ActionTypes, location_type : Globals.LocationTypes) -> ResourceQuantity:
	var multiplier : float = _get_total_bonus(quantity.name, action_type, location_type)
	var quantity_with_bonus : ResourceQuantity
	if multiplier != 1.0:
		quantity_with_bonus = ResourceBonusQuantity.new()
		quantity_with_bonus.multiplier = multiplier
	else:
		quantity_with_bonus = ResourceQuantity.new()
	quantity_with_bonus.copy_from(quantity)
	return quantity_with_bonus

func _add_quantity(quantity : ResourceQuantity):
	inventory_manager.add(quantity)
	_write_quantity(quantity)

func _add_by_name(quantity_name : StringName, amount : float):
	var quantity := ResourceQuantity.new()
	quantity.resource_unit = Globals.get_resource_unit(quantity_name)
	quantity.quantity = amount
	_add_quantity(quantity)

func _remove_quantity(quantity : ResourceQuantity):
	inventory_manager.remove(quantity)
	var inverse_quantity = quantity.duplicate()
	inverse_quantity.quantity *= -1.0
	_write_quantity(inverse_quantity)

func _remove_by_name(quantity_name : StringName, amount : float):
	var quantity := ResourceQuantity.new()
	quantity.resource_unit = Globals.get_resource_unit(quantity_name)
	quantity.quantity = amount
	_remove_quantity(quantity)

func _has_then_remove(resource_name : StringName, amount : float = 1) -> bool:
	if not inventory_manager.has(resource_name, amount):
		_write_failure("Requires %d %s." % [amount, resource_name])
		return false
	_remove_by_name(resource_name, amount)
	return true

func _on_action_done(action_type : Globals.ActionTypes, action_button : ActionButton):
	if not enabled: false
	# Match location actions
	if action_type in location_based_actions:
		city_container.animate_button_state(selected_location_action_button, false)
		city_container.animate_button_state(action_button, true)
		selected_location_action_button = action_button
		var location_data : LocationData = _get_action_location(action_type, action_button.waiting)
		if location_data and not action_button.waiting:
			_on_location_action_done(action_type, location_data, action_button)
		return
	if action_button.waiting: return
	match action_type:
		Globals.ActionTypes.LIBERATE:
			_write_success("You try liberating %s..." % city_name)
			if not _has_then_remove(&"activists", 60): return
			action_button.wait(10)
			await action_button.wait_time_passed
			_write_success("Liberated %s!" % city_name)
			city_liberated.emit()
		Globals.ActionTypes.SCOUT:
			_write_event("You try exploring the city...")
			if not _has_then_remove(&"energy", 1): return
			action_button.wait(10.0)
			await action_button.wait_time_passed
			var location_scouted = location_manager.scout()
			if location_scouted == null:
				_write_event("No new locations were discovered.")
			else:
				_write_discovered(location_scouted.name, "Location", true)
		Globals.ActionTypes.READ:
			_write_event("You try reading more secrets...")
			if not _has_then_remove(&"energy", 1): return
			action_button.wait(3.0)
			await action_button.wait_time_passed
			_write_success("Read...")
			knowledge_manager.read()
		Globals.ActionTypes.EAT:
			_write_success("You try eating...")
			if not _has_then_remove(&"food", 1): return
			action_button.wait(0.1)
			await action_button.wait_time_passed
			_write_success("Ate...")
			var total_energy = randi_range(1, 2) * _get_total_bonus(&"energy", action_type)
			_add_by_name(&"energy", total_energy)
		Globals.ActionTypes.COOK:
			_write_success("You try cooking...")
			if not _has_then_remove(&"raw ingredients", 3): return
			action_button.wait(15)
			await action_button.wait_time_passed
			_write_success("Cooked food...")
			var total_food = 10 * _get_total_bonus(&"food", action_type)
			_add_by_name(&"food", total_food)
		_:
			push_warning("No condition for action %s" % Globals.get_action_string(action_type))

func _get_quantity_or_zero(quantity_name: StringName, quantities_map : Dictionary[StringName, float]) -> float:
	if quantity_name in quantities_map:
		return quantities_map[quantity_name]
	return 0.0

func _roll_against_quantity(quantity_name: StringName, quantities_map : Dictionary[StringName, float], base_risk : float = 0.0) -> bool:
	return randf() > _get_quantity_or_zero(quantity_name, quantities_map) + base_risk

func _get_action_success(action_data : ActionData, location_data : LocationData) -> bool:
	var resource_quantities : Dictionary[StringName, float]
	for quantity_data in location_data.resources.quantities:
		resource_quantities[quantity_data.name] = quantity_data.quantity
	var action_base_risk = Globals.get_action_risk(action_data.action)
	var risky_resources = Globals.get_action_risky_resources(action_data.action)
	var final_state : bool = true
	for resource_name in risky_resources:
		final_state = final_state and _roll_against_quantity(resource_name, resource_quantities)
	return final_state

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
		_remove_quantity(cost)
	# Begin action
	action_button.wait(action_data.time_cost)
	if action_node.action_type == action_type and action_node.has_method(&"wait"):
		action_node.wait(true)
	await action_button.wait_time_passed
	if _get_action_success(action_data, location_data):
		if not action_data.success_message.is_empty():
			_write_success(action_data.success_message)
		for result in action_data.success_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			_add_quantity(quantity_with_bonus)
		for result in action_data.location_success_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			location_data.resources.add(quantity_with_bonus)
	else:
		if not action_data.failure_message.is_empty():
			_write_failure(action_data.failure_message)
		for result in action_data.failure_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			_add_quantity(quantity_with_bonus)
		for result in action_data.location_failure_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			location_data.resources.add(quantity_with_bonus)
	if action_node.action_type == action_type and action_node.has_method(&"wait"):
		action_node.wait(false)
#endregion

func _can_use_location_based_action(action_type : Globals.ActionTypes) -> bool:
	return action_type in discovered_actions and action_type in location_based_actions and action_type in location_manager.available_actions

func _can_use_location_action(action_type : Globals.ActionTypes) -> bool:
	for location_action in discovered_location_actions:
		if location_action.action_type != action_type: continue
		for location_data in location_manager.discovered_locations:
			if location_action.location_type != location_data.location_type: continue
			if location_data.has_action(action_type):
				return true
	return false

func _can_use_action(action_type : Globals.ActionTypes) -> bool:
	return (action_type in discovered_actions and action_type not in location_based_actions) or _can_use_location_based_action(action_type) or _can_use_location_action(action_type)

func _add_available_action(action_type : Globals.ActionTypes):
	if action_type in available_actions or not _can_use_action(action_type):
		return
	available_actions.append(action_type)
	city_container.add_action(action_type)

func _get_location_types_by_action(action_type : Globals.ActionTypes) -> Array[Globals.LocationTypes]:
	var actionable_locations : Array[Globals.LocationTypes]
	for location_action in discovered_location_actions:
		if location_action.action_type == action_type:
			actionable_locations.append(location_action.location_type)
	return actionable_locations

func _add_actionable_location_type(location_type : Globals.LocationTypes):
	if action_node is LocationActionBox:
		action_node.add_actionable_location_type(location_type)

func _on_location_discovered(location : LocationData):
	if location == null: 
		push_warning("no location provided to discover")
		return
	for action in location.actions_available:
		_add_available_action(action.action)
	if action_node is LocationActionBox:
		action_node.locations = location_manager.discovered_locations
		action_node.update_locations()

func discover_action(action_type : Globals.ActionTypes):
	if action_type in discovered_actions or action_type == Globals.ActionTypes.NONE: return
	discovered_actions.append(action_type)
	_write_discovered(Globals.get_action_string(action_type), "Action", false)
	_add_available_action(action_type)

func _on_action_learned(action_type : Globals.ActionTypes):
	discover_action(action_type)

func _has_discovered_location_action(location_action: Globals.LocationAction) -> bool:
	for discovered_location_action in discovered_location_actions:
		if location_action.location_type == discovered_location_action.location_type and\
		location_action.action_type == discovered_location_action.action_type:
			return true
	return false

func _discover_location_action(location_action: Globals.LocationAction):
	if _has_discovered_location_action(location_action): return
	discovered_location_actions.append(location_action)
	_write_discovered(location_action.get_string(), "Action", false)
	_add_available_action(location_action.action_type)

func _on_location_action_learned(location_action: Globals.LocationAction):
	_discover_location_action(location_action)

func _on_bonus_gained(bonus : Globals.Bonus):
	bonuses.append(bonus)
	if bonus is Globals.LocationActionResourceBonus:
		location_action_resource_bonuses.append(bonus)
	elif bonus is Globals.ActionResourceBonus:
		action_resource_bonuses.append(bonus)
	elif bonus is Globals.ResourceBonus:
		resource_bonuses.append(bonus)
	_write_bonus(bonus)

func discover_all_locations():
	var location_scouted = location_manager.scout()
	while (location_scouted):
		_write_discovered(location_scouted.name, "Location", true)
		location_scouted = location_manager.scout()
