@tool
extends VBoxContainer

signal action_done(action_data : ActionData, location_data : LocationData)

@export var action_type : Globals.ActionTypes :
	set(value):
		var _value_changed = action_type != value
		action_type = value
		if is_inside_tree() and _value_changed:
			_set_button()
	
@export var locations : Array[LocationData] :
	set(value):
		var _value_changed = locations != value
		locations = value
		if is_inside_tree() and _value_changed:
			_update_locations()

var _selected_location : LocationData

func _clear_tree():
	%Tree.clear()
	%Tree.create_item()
	%ActionButton.disabled = true

func _add_location_as_tree_item(location_data : LocationData):
	var action_tree_item : TreeItem = %Tree.create_item()
	action_tree_item.set_text(0, location_data.name)
	if location_data == _selected_location:
		action_tree_item.select(0)

func _add_locations_items():
	for location in locations:
		_add_location_as_tree_item(location)

func add_location(location: LocationData):
	if location not in locations:
		locations.append(location)
		_add_location_as_tree_item(location)

func _update_locations():
	_clear_tree()
	_add_locations_items()

func _set_button():
	%ActionButton.text = Globals.get_action_string(action_type)

func _ready():
	action_type = action_type
	_set_button()
	_update_locations()

func _action_done_on_location():
	var _location_action_data : ActionData
	if _selected_location == null : return
	var actions_available : Array = []
	for action in _selected_location.actions_available:
		if action.action == action_type:
			actions_available.append(action)
	if actions_available.size() == 0 : return
	var random_action = actions_available.pick_random()
	action_done.emit(random_action, _selected_location)

func _on_action_button_pressed():
	_action_done_on_location()

func _get_selected_location():
	var _selected_item: TreeItem = %Tree.get_selected()
	if _selected_item == null: return
	for location in locations:
		if location.name == _selected_item.get_text(0):
			_selected_location = location
			return

func _on_tree_item_selected():
	%ActionButton.disabled = false
	_get_selected_location()
