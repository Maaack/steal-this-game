class_name LocationData
extends Resource

@export var location_type : Globals.LocationTypes
@export var name : String
@export_multiline var description : String
@export var actions_available : Array[ActionData]

var resources : ResourceContainer = ResourceContainer.new()

func get_location_string():
	return Globals.get_location_string(location_type)
