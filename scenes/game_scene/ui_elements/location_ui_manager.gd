@tool
extends Node

@export var location_action_scene : PackedScene
@export var location_manager : LocationManager
@export var location_action_container : Container

var action_map : Dictionary

func _add_location_action_container() -> Node:
	var instance = location_action_scene.instantiate()
	location_action_container.add_child(instance)
	return instance

func _on_location_discovered(location : LocationData):
	for action in location.actions_available:
		if not action.action in action_map:
			var location_action_container = _add_location_action_container()
			location_action_container.action_type = action.action
			action_map[action.action] = location_action_container
		var container = action_map[action.action]
		container.add_location(location)

func _ready():
	location_manager.location_discovered.connect(_on_location_discovered)
