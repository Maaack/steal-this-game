class_name ResourceUnit
extends Resource

@export var name : StringName
@export var icon : Texture

func _to_string():
	return "%s (%d)" % [name, get_instance_id()]

func copy_from(value:ResourceUnit):
	if value == null:
		return
	name = value.name
	icon = value.icon
