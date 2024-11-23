@tool
extends VBoxContainer

signal action_done(action_data : ActionData, location_data : LocationData, action_button : ActionButton)

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
@export var resource_meter_scene : PackedScene

@onready var resource_container : Container = %ResourceContainer

var resource_meter_map : Dictionary[StringName, ResourceMeter]
var _selected_location : LocationData
var _selectable_items : Array[TreeItem]

func _clear_tree():
	%Tree.clear()
	%Tree.create_item()
	%ActionButton.disabled = true

func _add_location_as_tree_item(location_data : LocationData):
	var action_tree_item : TreeItem = %Tree.create_item()
	action_tree_item.set_text(0, location_data.name)
	_selectable_items.append(action_tree_item)
	if location_data == _selected_location:
		action_tree_item.select(0)

func _select_first_if_null():
	if _selected_location == null and _selectable_items.size() > 0:
		_selectable_items[0].select(0)
		_update_selected_location()

func _add_locations_items():
	for location in locations:
		_add_location_as_tree_item(location)

func add_location(location: LocationData):
	if location not in locations:
		locations.append(location)
		_add_location_as_tree_item(location)
	_select_first_if_null()

func _update_locations():
	_clear_tree()
	_add_locations_items()
	_select_first_if_null()

func _set_button():
	%ActionButton.text = Globals.get_action_string(action_type)

func _ready():
	action_type = action_type
	_set_button()
	_update_locations()

func _update_bar_with_resource(resource_meter : ResourceMeter, resource_name : String):
	var quantity : float = 0
	if _selected_location != null: 
		var quantity_data = _selected_location.resources.find_quantity(resource_name)
		if quantity_data != null:
			quantity = quantity_data.quantity
	resource_meter.progress = quantity

func _action_done_on_location():
	var _location_action_data : ActionData
	if _selected_location == null : return
	var actions_available : Array = []
	for action in _selected_location.actions_available:
		if action.action == action_type:
			actions_available.append(action)
	if actions_available.size() == 0 : return
	var random_action : ActionData = actions_available.pick_random()
	action_done.emit(random_action, _selected_location, %ActionButton)
	_update_selected_location_resource_meters()

func _on_action_button_pressed():
	_action_done_on_location()

func _clear_resource_container():
	resource_meter_map.clear()
	for child in resource_container.get_children():
		child.queue_free()

func _add_meter_for_resource(quantity : ResourceQuantity):
	if quantity.name in resource_meter_map: return
	var resource_meter_instance = resource_meter_scene.instantiate()
	if not resource_meter_instance is ResourceMeter: return
	resource_meter_instance.resource_name = quantity.name
	resource_meter_instance.icon = quantity.icon
	resource_meter_instance.progress = quantity.quantity
	resource_container.add_child(resource_meter_instance)
	resource_meter_map[quantity.name] = resource_meter_instance

func _update_selected_location_resource_meters():
	_clear_resource_container()
	for quantity in _selected_location.resources.contents:
		_add_meter_for_resource(quantity)

func _update_selected_location_details():
	%NameLabel.text = _selected_location.name
	%TypeLabel.text = _selected_location.get_location_string()
	%DescriptionLabel.text = _selected_location.description
	_update_selected_location_resource_meters()

func _update_selected_location():
	var _selected_item: TreeItem = %Tree.get_selected()
	if _selected_item == null: return
	for location in locations:
		if location.name == _selected_item.get_text(0):
			_selected_location = location
			break
	_update_selected_location_details()

func _on_tree_item_selected():
	%ActionButton.disabled = false
	_update_selected_location()

func _process(delta):
	for resource_name in resource_meter_map:
		var resource_instance = resource_meter_map[resource_name]
		_update_bar_with_resource(resource_instance, resource_name)

func tick(delta: float):
	%ActionButton.tick(delta)
