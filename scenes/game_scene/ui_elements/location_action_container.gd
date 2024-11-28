@tool
class_name LocationActionBox
extends BoxContainer

signal action_done(action_data : ActionData, location_data : LocationData, action_button : ActionButton)
signal selected_location_changed(location_data : LocationData)

@export var action_type : Globals.ActionTypes :
	set(value):
		var _value_changed = action_type != value
		action_type = value
		if is_inside_tree() and _value_changed:
			update_locations()
			_set_label()
			_set_button()
	
@export var locations : Array[LocationData] :
	set(value):
		var _value_changed = locations != value
		locations = value
		if is_inside_tree() and _value_changed:
			update_locations()
@export var resource_meter_scene : PackedScene
@export var success_color: Color = Color.WHITE
@export var failure_color: Color = Color.WHITE

@onready var resource_container : Container = %ResourceContainer

var actionable_location_types : Array[Globals.LocationTypes] :
	set(value):
		var _value_changed = actionable_location_types != value
		actionable_location_types = value
		if is_inside_tree() and _value_changed:
			update_locations()

var resource_meter_map : Dictionary[StringName, ResourceMeter]
var selected_location : LocationData :
	set(value):
		var _value_changed = selected_location != value
		selected_location = value
		if _value_changed:
			_refresh_selected_location()
			selected_location_changed.emit(selected_location, action_type)

var _selectable_item_map : Dictionary[TreeItem, LocationData]

func _clear_tree():
	%Tree.clear()
	%Tree.create_item()
	_selectable_item_map.clear()

func _add_location_as_tree_item(location_data : LocationData):
	var action_tree_item : TreeItem = %Tree.create_item()
	action_tree_item.set_text(0, location_data.name)
	_selectable_item_map[action_tree_item] = location_data
	if location_data == selected_location:
		action_tree_item.select(0)

func _refresh_selected_location():
	for tree_item in _selectable_item_map:
		# Select first if none selected
		if selected_location == null:
			if not tree_item.is_selected(0):
				tree_item.select(0)
			return
		else:
			var location_data = _selectable_item_map[tree_item]
			if location_data == selected_location:
				if not tree_item.is_selected(0):
					tree_item.select(0)
				return

func _add_locations_items():
	for location in locations:
		if location.has_action(action_type):
			if actionable_location_types.size() > 0 and location.location_type not in actionable_location_types:
				continue
			_add_location_as_tree_item(location)

func add_location(location: LocationData):
	if location not in locations:
		locations.append(location)
		update_locations()
	_refresh_selected_location()

func add_actionable_location_type(location_type : Globals.LocationTypes):
	if location_type not in actionable_location_types:
		actionable_location_types.append(location_type)
		update_locations()
	_refresh_selected_location()

func update_locations():
	_clear_tree()
	_add_locations_items()
	_refresh_selected_location()

func _set_label():
	%ActionLabel.text = Globals.get_action_string(action_type)

func _set_button():
	%ActionButton.text = Globals.get_action_string(action_type)

func _ready():
	action_type = action_type
	_set_button()
	update_locations()

func _update_bar_with_resource(resource_meter : ResourceMeter, resource_name : String):
	var quantity : float = 0
	if selected_location != null: 
		var quantity_data = selected_location.resources.find_quantity(resource_name)
		if quantity_data != null:
			quantity = quantity_data.quantity
	resource_meter.progress = quantity

func _action_done_on_location():
	var _location_action_data : ActionData
	if selected_location == null : return
	var actions_available : Array = []
	for action in selected_location.actions_available:
		if action.action == action_type:
			actions_available.append(action)
	if actions_available.size() == 0 : return
	var random_action : ActionData = actions_available.pick_random()
	action_done.emit(random_action, selected_location, %ActionButton)
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
	resource_meter_instance.good = false
	resource_container.add_child(resource_meter_instance)
	resource_meter_map[quantity.name] = resource_meter_instance

func _update_selected_location_resource_meters():
	_clear_resource_container()
	for quantity in selected_location.resources.contents:
		_add_meter_for_resource(quantity)

func _clear_action_details():
	for child in %CostsContainer.get_children():
		child.queue_free()
	for child in %SuccessContainer.get_children():
		child.queue_free()
	for child in %FailureContainer.get_children():
		child.queue_free()

func _get_new_rich_text_label() -> RichTextLabel:
	var label = RichTextLabel.new()
	label.scroll_active = false
	label.fit_content = true
	label.bbcode_enabled = true
	return label

func _add_label_for_quantity(quantity : ResourceQuantity, container : Control, percent : bool = false, good : bool = true):
	var label = _get_new_rich_text_label()
	var quantity_string : String
	if quantity.name == &"time":
		quantity_string = "%.0f sec." % quantity.quantity
	elif percent:
		quantity_string = "%+.0f%%" % (quantity.quantity * 100)
	elif quantity is ResourceRandIQuantity and (quantity.quantity_min != 0 or quantity.quantity_max != 0):
		var sign_string : String = "+"
		quantity.quantity = quantity.quantity_min if quantity.quantity_min != 0 else quantity.quantity_max
		if quantity.quantity < 0:
			sign_string = "-"
		quantity_string = "%s(%.0f - %.0f)" % [sign_string, quantity.quantity_min, quantity.quantity_max]
	else:
		quantity_string = "%+.0f" % quantity.quantity
	var color_string : String
	if (quantity.quantity >= 0 and good) or (quantity.quantity <= 0 and not good):
		color_string = success_color.to_html(false)
	else:
		color_string = failure_color.to_html(false)

	label.text = "[img=16x16]%s[/img] %s [color=#%s][b]%s[/b][/color]" % [quantity.icon.resource_path, quantity.name.capitalize(), color_string, quantity_string]
	container.add_child(label)
	return label

func _add_action_time_cost(action : ActionData):
	var quantity := ResourceQuantity.new()
	quantity.resource_unit = Globals.get_resource_unit(&"time")
	quantity.quantity = action.time_cost
	_add_label_for_quantity(quantity, %CostsContainer, false, false)

func _add_details_for_action(action : ActionData):
	_add_action_time_cost(action)
	for quantity in action.resource_cost:
		quantity = quantity.duplicate()
		quantity.quantity *= -1.0
		_add_label_for_quantity(quantity, %CostsContainer)
	for quantity in action.success_resource_result:
		_add_label_for_quantity(quantity, %SuccessContainer)
	for quantity in action.location_success_resource_result:
		var label = _add_label_for_quantity(quantity, %SuccessContainer, true, false)
		label.text = "%s [i](Local)[/i]" % label.text
	for quantity in action.failure_resource_result:
		_add_label_for_quantity(quantity, %FailureContainer)
	for quantity in action.location_failure_resource_result:
		var label = _add_label_for_quantity(quantity, %FailureContainer, true, false)
		label.text = "%s [i](Local)[/i]" % label.text

func _update_selected_location_action_details():
	_clear_action_details()
	for action in selected_location.actions_available:
		if action.action == action_type:
			_add_details_for_action(action)

func _update_selected_location_details():
	%NameLabel.text = selected_location.name
	%TypeLabel.text = selected_location.get_location_string()
	%DescriptionLabel.text = selected_location.description
	_update_selected_location_action_details()
	_update_selected_location_resource_meters()

func _update_selected_location():
	var _selected_item: TreeItem = %Tree.get_selected()
	if _selected_item == null: return
	for location in locations:
		if location.name == _selected_item.get_text(0):
			selected_location = location
			break
	_update_selected_location_details()

func _on_tree_item_selected():
	_update_selected_location()

func _process(delta):
	if selected_location == null: return
	for quantity in selected_location.resources.quantities:
		if quantity.name not in resource_meter_map:
			_add_meter_for_resource(quantity)
	for resource_name in resource_meter_map:
		var resource_instance = resource_meter_map[resource_name]
		_update_bar_with_resource(resource_instance, resource_name)

func tick(delta: float):
	%ActionButton.tick(delta)

func _on_action_button_wait_time_passed():
	_update_selected_location_resource_meters.call_deferred()

func wait(flag: bool = true):
	if flag:
		%ActionLabel.theme_type_variation = &"DisabledLabel"
	else:
		%ActionLabel.theme_type_variation = &"SelectedLabel"
