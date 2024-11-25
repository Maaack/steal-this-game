class_name LocationData
extends Resource

@export var location_type : Globals.LocationTypes
@export var name : String
@export_multiline var description : String
@export var actions_available : Array[ActionData]

var resources : ResourceContainer = ResourceContainer.new()

func get_location_string():
	return Globals.get_location_string(location_type)

func has_action(action_type : Globals.ActionTypes) -> bool:
	for action in actions_available:
		if action.action == action_type:
			return true
	return false

func get_action(action_type : Globals.ActionTypes) -> ActionData:
	var specific_actions_available : Array = []
	for action in actions_available:
		if action.action == action_type:
			specific_actions_available.append(action)
	if specific_actions_available.size() == 0 : return null
	return specific_actions_available.pick_random()
