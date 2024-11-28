class_name CityContainer
extends VBoxContainer

signal action_done(action : Globals.ActionTypes, action_button : ActionButton)

@export var city_name : String :
	set(value):
		city_name = value
		if is_inside_tree():
			%CityLabel.text = city_name
@export var action_button_scene : PackedScene
@export var active_button_offset : Vector2
@export var active_button_animation_time : float

var action_type_button_map : Dictionary[Globals.ActionTypes, ActionButton]
var button_action_type_map : Dictionary[ActionButton, Globals.ActionTypes]
var selected_action_button : ActionButton
var active_action_type : Globals.ActionTypes = -1
var button_position_map : Dictionary[ActionButton, Vector2] 

func _clear_actions():
	for child in %ActionsContainer.get_children():
		child.queue_free()
	button_position_map.clear()
	action_type_button_map.clear()
	button_action_type_map.clear()
	selected_action_button = null

func _set_active_button_offset():
	if active_action_type not in action_type_button_map: return
	var active_button = action_type_button_map[active_action_type]
	active_button.position += active_button_offset

func _save_button_position(button : ActionButton):
	if button not in button_position_map:
		button_position_map[button] = button.position

func _add_action_button(action_type : Globals.ActionTypes) -> ActionButton :
	var button : ActionButton = action_button_scene.instantiate()
	button.text = Globals.get_action_string(action_type)
	button.pressed.connect(_on_action_pressed.bind(action_type, button))
	%ActionsContainer.add_child(button)
	action_type_button_map[action_type] = button
	button_action_type_map[button] = action_type
	_save_button_position.call_deferred(button)
	return button

func add_action(action_type : Globals.ActionTypes) -> ActionButton:
	if action_type in action_type_button_map:
		return action_type_button_map[action_type]
	else:
		return _add_action_button(action_type)

func _on_action_pressed(action_type : Globals.ActionTypes, action_button : ActionButton):
	selected_action_button = action_button
	action_done.emit(action_type, action_button)

func tick(delta: float):
	for action_type in action_type_button_map:
		var button : ActionButton = action_type_button_map[action_type]
		button.tick(delta)

func animate_button_state(action_button : ActionButton, active: bool):
	if action_button == null or action_button not in button_position_map: return
	var original_position = button_position_map[action_button]
	var tween = create_tween()
	if active:
		active_action_type = button_action_type_map[action_button]
		tween.tween_property(action_button, "position", original_position + active_button_offset, active_button_animation_time)
	else:
		tween.tween_property(action_button, "position", original_position, active_button_animation_time)

func _on_actions_container_item_rect_changed():
	_set_active_button_offset.call_deferred()
