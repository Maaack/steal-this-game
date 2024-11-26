extends Node

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			city_container.city_name = city_name
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
@export var action_container : Container
@export var city_container : CityContainer
@export var event_view : EventView
@export var location_action_scene : PackedScene

var discovered_location_actions : Array[Globals.LocationAction]
var action_node : Control
var detailed_action_type : Globals.ActionTypes
var selected_location_map : Dictionary[Globals.ActionTypes, LocationData]
var bonuses : Array[Globals.Bonus]

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
	event_view.add_quantity_text(quantity)
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

func _get_location_action_resource_bonus(bonuses_ref : Array[Globals.Bonus], resource_name: StringName, action_type : Globals.ActionTypes, location_type : Globals.LocationTypes) -> float:
	var multiplier : float = 1.0
	var used : Array[Globals.Bonus]
	for bonus in bonuses_ref:
		if bonus is Globals.LocationActionResourceBonus:
			if bonus.resource_name == resource_name and \
			bonus.action_type == action_type and \
			bonus.location_type == location_type:
				multiplier *= bonus.get_multiplier()
				used.append(bonus)
	for bonus in used:
		bonuses_ref.erase(bonus)
	return multiplier
	
func _get_action_resource_bonus(bonuses_ref : Array[Globals.Bonus], resource_name: StringName, action_type : Globals.ActionTypes) -> float:
	var multiplier : float = 1.0
	var used : Array[Globals.Bonus]
	for bonus in bonuses_ref:
		if bonus is Globals.ActionResourceBonus:
			if bonus.resource_name == resource_name and \
			bonus.action_type == action_type:
				multiplier *= bonus.get_multiplier()
				used.append(bonus)
	for bonus in used:
		bonuses_ref.erase(bonus)
	return multiplier
	
func _get_resource_bonus(bonuses_ref : Array[Globals.Bonus], resource_name: StringName) -> float:
	var multiplier : float = 1.0
	var used : Array[Globals.Bonus]
	for bonus in bonuses_ref:
		if bonus is Globals.ResourceBonus:
			if bonus.resource_name == resource_name:
				multiplier *= bonus.get_multiplier()
				used.append(bonus)
	for bonus in used:
		bonuses_ref.erase(bonus)
	return multiplier

func _get_total_bonus(bonuses_ref : Array[Globals.Bonus], resource_name: StringName, action_type : Globals.ActionTypes, location_type : Globals.LocationTypes) -> float:
	bonuses_ref = bonuses_ref.duplicate()
	var multiplier : float = 1.0
	multiplier *= _get_location_action_resource_bonus(bonuses_ref, resource_name, action_type, location_type)
	multiplier *= _get_action_resource_bonus(bonuses_ref, resource_name, action_type)
	multiplier *= _get_resource_bonus(bonuses_ref, resource_name)
	return multiplier

func _get_quantity_with_bonus(quantity : ResourceQuantity, action_type : Globals.ActionTypes, location_type : Globals.LocationTypes) -> ResourceQuantity:
	var multiplier : float = _get_total_bonus(bonuses, quantity.name, action_type, location_type)
	var quantity_with_bonus : ResourceQuantity
	if multiplier != 1.0:
		quantity_with_bonus = ResourceBonusQuantity.new()
		quantity_with_bonus.multiplier = multiplier
	else:
		quantity_with_bonus = ResourceQuantity.new()
	quantity_with_bonus.copy_from(quantity)
	return quantity_with_bonus

func _on_action_done(action_type : Globals.ActionTypes, action_button : ActionButton):
	# Match location actions
	if action_type in location_based_actions:
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
				_write_discovered(location_scouted.name, "Location", true)
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
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			inventory_manager.add(quantity_with_bonus)
			_write_quantity(quantity_with_bonus)
		for result in action_data.location_success_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			location_data.resources.add(quantity_with_bonus)
	else:
		if not action_data.failure_message.is_empty():
			_write_failure(action_data.failure_message)
		for result in action_data.failure_resource_result:
			var quantity_with_bonus = _get_quantity_with_bonus(result, action_type, location_data.location_type)
			inventory_manager.add(quantity_with_bonus)
			_write_quantity(quantity_with_bonus)
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

func _discover_action(action_type : Globals.ActionTypes):
	if action_type in discovered_actions: return
	discovered_actions.append(action_type)
	_write_discovered(Globals.get_action_string(action_type), "Action", false)
	_add_available_action(action_type)

func _on_action_learned(action_type : Globals.ActionTypes):
	_discover_action(action_type)

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
	_write_bonus(bonus)
