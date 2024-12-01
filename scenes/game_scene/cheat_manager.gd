class_name CheatManager
extends Node

@export var inventory_manager : InventoryManager
@export var action_manager : ActionManager
@export var event_view : EventView
@export var reset_delay : float = 3.0

var reset_timer : float
var code : String

func reset_code():
	code = ""

func check_code():
	if code.containsn("extra"):
		event_view.add_success_text("Cheat activated!")
		inventory_manager.add_by_name(&"food", 5000)
		inventory_manager.add_by_name(&"clothes", 200)
		reset_code()
	if code.containsn("love"):
		event_view.add_success_text("Cheat activated!")
		inventory_manager.add_by_name(&"determination", 100)
		inventory_manager.add_by_name(&"reputation", 1000)
		reset_code()
	if code.containsn("brothers") or code.containsn("sisters"):
		event_view.add_success_text("Cheat activated!")
		inventory_manager.add_by_name(&"activists", 25)
		reset_code()
	if code.containsn("peace"):
		event_view.add_success_text("Cheat activated!")
		for action_type in Globals.ActionTypes:
			action_manager.discover_action(Globals.ActionTypes[action_type])
	if code.containsn("blood"):
		event_view.add_success_text("Cheat activated!")
		inventory_manager.add_by_name(&"money", 1000)
		reset_code()
	if code.containsn("vision"):
		event_view.add_success_text("Cheat activated!")
		action_manager.discover_all_locations()
		reset_code()

func _unhandled_key_input(event):
	if event is InputEventKey and event.is_pressed():
		var key : String = event.as_text_key_label()
		code += key
		reset_timer = reset_delay
		check_code()

func _process(delta):
	if reset_timer > 0:
		reset_timer -= min(delta, reset_timer)
		if is_zero_approx(reset_timer):
			reset_code()
