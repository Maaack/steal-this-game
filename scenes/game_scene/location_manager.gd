@tool
class_name LocationManager
extends DirectoryReader

signal location_discovered(location_data : LocationData)

@export var city_locations : Array[LocationData]
@export var starting_locations : Array[LocationData]
@export_tool_button("Refresh Locations") var _refresh_locations_action = _refresh_locations

var undiscovered_locations : Array[LocationData]
var discovered_locations : Array[LocationData]

func discover_location(discovered_location : LocationData):
	discovered_locations.append(discovered_location)
	if discovered_location in undiscovered_locations:
		undiscovered_locations.erase(discovered_location)
	location_discovered.emit(discovered_location)

func _fill_starting_locations():
	for location in starting_locations:
		discover_location(location)
	for location in city_locations:
		if location in starting_locations: continue
		undiscovered_locations.append(location)

func _refresh_locations():
	city_locations.clear()
	for file in files:
		var location_data : Resource = load(file)
		if location_data is LocationData:
			city_locations.append(location_data)

func _ready():
	if Engine.is_editor_hint(): return
	directory = directory
	_refresh_files()
	_refresh_locations()
	_fill_starting_locations.call_deferred()

func scout() -> LocationData:
	if undiscovered_locations.size() == 0: 
		return
	var location : LocationData = undiscovered_locations.pick_random()
	discover_location(location)
	return location
