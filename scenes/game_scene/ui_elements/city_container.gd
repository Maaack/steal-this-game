@tool
extends VBoxContainer

signal action_done(action : Globals.ActionTypes)

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			%CityLabel.text = city_name
@export var city_actions : Array[Globals.ActionTypes] :
	set(value):
		city_actions = value
		if is_inside_tree():
			_update_actions()
@export var action_button_scene : PackedScene

func _clear_actions():
	for child in %ActionsContainer.get_children():
		child.queue_free()

func _update_actions():
	_clear_actions()
	for action_type in city_actions:
		var button : Button = action_button_scene.instantiate()
		button.text = Globals.get_action_string(action_type)
		button.pressed.connect(_on_action_pressed.bind(action_type))
		%ActionsContainer.add_child(button)

func _ready():
	city_name = city_name

func _on_action_pressed(action_type : Globals.ActionTypes):
	action_done.emit(action_type)

func tick(delta: float):
	for child in %ActionsContainer.get_children():
		if child is ActionButton:
			child.tick(delta)
