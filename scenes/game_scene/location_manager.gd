class_name LocationManager
extends Node

signal location_discovered(location_data : LocationData)

@export var city_locations : Array[LocationData]
@export var starting_locations : Array[LocationData]

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

func _ready():
	_fill_starting_locations.call_deferred()

func scout() -> LocationData:
	if undiscovered_locations.size() == 0: 
		return
	var location : LocationData = undiscovered_locations.pick_random()
	discover_location(location)
	return location
