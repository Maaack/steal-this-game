@tool
extends HBoxContainer

@export var resource_name : String :
	set(value):
		resource_name = value
		tooltip_text = resource_name
@export var icon : Texture :
	set(value):
		icon = value
		if is_inside_tree():
			$TextureRect.texture = icon
@export var quantity : int = 0 :
	set(value):
		quantity = value
		if is_inside_tree():
			_update_label()
@export var max_quantity : int = 0 :
	set(value):
		max_quantity = value
		if is_inside_tree():
			_update_label()

func _update_label():
	if max_quantity > 0:
		$Label.text = "%d / %d" % [quantity, max_quantity]
	else:
		$Label.text = "%d" % quantity
