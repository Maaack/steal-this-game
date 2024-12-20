@tool
class_name LocationManager
extends DirectoryReader

signal location_discovered(location_data : LocationData)

@export var city_locations : Array[LocationData]
@export var starting_locations : Array[LocationData]
@export_tool_button("Refresh Locations") var _refresh_locations_action = _refresh_locations

var undiscovered_locations : Array[LocationData]
var discovered_locations : Array[LocationData]
var available_actions : Array[Globals.ActionTypes]

#Loads Json to Dictionary
func _read_json_from_file(file_path) -> Dictionary:
	assert (FileAccess.file_exists(file_path))
	var file = FileAccess.open(file_path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var json_data = test_json_conv.get_data()
	file.close()
	assert (json_data.size()>0)
	return json_data

func _get_quantity_for_resource(resource) -> ResourceQuantity:
	var _quantity : ResourceQuantity
	if "quantity" in resource:
		_quantity = ResourceQuantity.new()
		_quantity.quantity = resource["quantity"]
	elif "quantity_max" in resource and "quantity_min" in resource:
		_quantity = ResourceRandIQuantity.new()
		_quantity.quantity_max = resource["quantity_max"]
		_quantity.quantity_min = resource["quantity_min"]
		_quantity.quantity = 0
	else:
		push_warning("resource missing quantity")
	if "name" in resource:
		_quantity.resource_unit = Globals.get_resource_unit(resource["name"])
	else:
		push_warning("resource missing name")
	return _quantity

func _parse_locations(locations : Array) -> Array:
	var parsed_locations : Array = []
	for _location in locations:
		var location_data = LocationData.new()
		if "name" in _location:
			location_data.name = _location["name"]
		if "location_type" in _location:
			location_data.location_type = _location["location_type"]
		if "description" in _location:
			location_data.description = _location["description"]
		if "resources" in _location:
			for _resource in _location["resources"]:
				var _quantity = _get_quantity_for_resource(_resource)
				location_data.resources.add(_quantity)
		if "actions_available" in _location:
			var _actions : Array = _location["actions_available"]
			for _action in _actions:
				var action_data := ActionData.new()
				if "action_type" in _action:
					action_data.action = _action["action_type"]
				if "try_message" in _action:
					action_data.try_message = _action["try_message"]
				if "time_cost" in _action:
					action_data.time_cost = _action["time_cost"]
				else:
					push_warning("%s at %s has no set time_cost" % [action_data.action, location_data.name])
				if "resource_cost" in _action:
					var _resources : Array = _action["resource_cost"]
					for _resource in _resources:
						var _quantity = _get_quantity_for_resource(_resource)
						action_data.resource_cost.append(_quantity)
				if "success_message" in _action:
					action_data.success_message = _action["success_message"]
				if "success_resource_result" in _action:
					var _resources : Array = _action["success_resource_result"]
					for _resource in _resources:
						var _quantity = _get_quantity_for_resource(_resource)
						action_data.success_resource_result.append(_quantity)
				if "location_success_resource_result" in _action:
					var _resources : Array = _action["location_success_resource_result"]
					for _resource in _resources:
						var _quantity = _get_quantity_for_resource(_resource)
						action_data.location_success_resource_result.append(_quantity)
				if "failure_message" in _action:
					action_data.failure_message = _action["failure_message"]
				if "failure_resource_result" in _action:
					var _resources : Array = _action["failure_resource_result"]
					for _resource in _resources:
						var _quantity = _get_quantity_for_resource(_resource)
						action_data.failure_resource_result.append(_quantity)
				if "location_failure_resource_result" in _action:
					var _resources : Array = _action["location_failure_resource_result"]
					for _resource in _resources:
						var _quantity = _get_quantity_for_resource(_resource)
						action_data.location_failure_resource_result.append(_quantity)
				location_data.actions_available.append(action_data)
		parsed_locations.append(location_data)
	return parsed_locations

func _parse_location_file(file_path) -> Array:
	var json_data = _read_json_from_file(file_path)
	if "locations" in json_data:
		return _parse_locations(json_data["locations"])
	return []

func discover_location(discovered_location : LocationData):
	discovered_locations.append(discovered_location)
	if discovered_location in undiscovered_locations:
		undiscovered_locations.erase(discovered_location)
	for action_data in discovered_location.actions_available:
		if action_data.action not in available_actions:
			available_actions.append(action_data.action)
	location_discovered.emit(discovered_location)

func fill_starting_locations():
	for location in starting_locations:
		discover_location(location)
	for location in city_locations:
		if location in starting_locations: continue
		undiscovered_locations.append(location)

func _refresh_locations():
	city_locations.clear()
	if extension == "json":
		for file in files:
			var parsed_locations = _parse_location_file(file)
			city_locations.append_array(parsed_locations)
		return
	for file in files:
		var location_data : Resource = load(file)
		if location_data is LocationData:
			city_locations.append(location_data)

func _ready():
	if Engine.is_editor_hint(): return
	directory = directory
	_refresh_files()
	if extension == "json":
		for file in files:
			var parsed_locations = _parse_location_file(file)
			city_locations.append_array(parsed_locations)
	_refresh_locations()

func scout() -> LocationData:
	if undiscovered_locations.size() == 0: 
		return
	var location : LocationData = undiscovered_locations.pick_random()
	discover_location(location)
	return location
