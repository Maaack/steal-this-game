@tool
class_name ResourceMeter
extends HBoxContainer

@export var icon : Texture :
	set(value):
		icon = value
		if is_inside_tree():
			%TextureRect.texture = icon
@export var progress : float = 0.0 :
	set(value):
		progress = value
		if is_inside_tree():
			%ProgressBar.value = progress
@export var resource_name : String :
	set(value):
		resource_name = value
		tooltip_text = resource_name
@export var good : bool :
	set(value):
		good = value
		if is_inside_tree():
			if good:
				%ProgressBar.theme_type_variation = &"ProgressBarGood"
			else:
				%ProgressBar.theme_type_variation = &"ProgressBarBad"

func _ready():
	icon = icon
	progress = progress
	good = good
