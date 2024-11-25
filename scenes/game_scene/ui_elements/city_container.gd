class_name CityContainer
extends VBoxContainer

signal action_done(action : Globals.ActionTypes, action_button : ActionButton)

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			%CityLabel.text = city_name
@export var action_button_scene : PackedScene

var city_action_button_map : Dictionary[Globals.ActionTypes, ActionButton]

func _clear_actions():
	for child in %ActionsContainer.get_children():
		child.queue_free()

func _add_action_button(action_type : Globals.ActionTypes) -> ActionButton :
	var button : Button = action_button_scene.instantiate()
	button.text = Globals.get_action_string(action_type)
	button.pressed.connect(_on_action_pressed.bind(action_type, button))
	%ActionsContainer.add_child(button)
	city_action_button_map[action_type] = button
	return button

func add_action(action_type : Globals.ActionTypes) -> ActionButton:
	if action_type in city_action_button_map:
		return city_action_button_map[action_type]
	else:
		return _add_action_button(action_type)

func _on_action_pressed(action_type : Globals.ActionTypes, action_button : ActionButton):
	action_done.emit(action_type, action_button)

func tick(delta: float):
	for action_type in city_action_button_map:
		var button : ActionButton = city_action_button_map[action_type]
		button.tick(delta)
