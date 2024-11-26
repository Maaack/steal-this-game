@tool
class_name KnowledgeManager
extends DirectoryReader

signal action_learned(action_type : Globals.ActionTypes)
signal location_action_learned(location_action : Globals.LocationAction)
signal bonus_gained(bonus : Globals.Bonus)

@export_multiline var end_reached_message : String = ""
@export var inventory_manager : InventoryManager
@export var event_view : EventView

class KnowledgePart :
	var text : String
	var resources : Array[ResourceQuantity]
	var action_unlocks : Array[Globals.ActionTypes]
	var location_action_unlocks : Array[Globals.LocationAction]
	var bonuses : Array[Globals.Bonus]

var undiscovered_knowledge : Array[KnowledgePart] = []
var discovered_knowledge : Array[KnowledgePart] = []

#Loads Json to Dictionary
func _read_json_from_file(file_path) -> Dictionary:
	assert (FileAccess.file_exists(file_path))
	var file = FileAccess.open(file_path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var json_data = test_json_conv.get_data()
	file.close()
	assert (json_data.size()>0)
	return json_data

func _parse_knowledge_parts(parts : Array) -> Array:
	var parsed_parts : Array = []
	for part in parts:
		var knowledge_part = KnowledgePart.new()
		if "text" in part:
			knowledge_part.text = part["text"]
		if "resources" in part:
			var resources_array : Array = part["resources"]
			for resource in resources_array:
				var resource_quantity := ResourceQuantity.new()
				resource_quantity.resource_unit = Globals.get_resource_unit(resource["name"])
				resource_quantity.quantity = resource["quantity"]
				knowledge_part.resources.append(resource_quantity)
		if "action_unlocks" in part:
			for action_type_int in part["action_unlocks"]:
				knowledge_part.action_unlocks.append(action_type_int as Globals.ActionTypes)
		if "location_action_unlocks" in part:
			for location_action_parts in part["location_action_unlocks"]:
				var location_action = Globals.LocationAction.new()
				if "location_type" in location_action_parts:
					location_action.location_type = location_action_parts["location_type"]
				else:
					push_warning("location action missing location_type")
				if "action_type" in location_action_parts:
					location_action.action_type = location_action_parts["action_type"]
				else:
					push_warning("location action missing action_type")
				knowledge_part.location_action_unlocks.append(location_action)
		if "bonuses" in part:
			for bonus_parts in part["bonuses"]:
				var bonus : Globals.Bonus
				if "location_type" in bonus_parts:
					if bonus == null: bonus = Globals.LocationActionResourceBonus.new()
					bonus.location_type = bonus_parts["location_type"]
				if "action_type" in bonus_parts:
					if bonus == null: bonus = Globals.ActionResourceBonus.new()
					bonus.action_type = bonus_parts["action_type"]
				if "resource_name" in bonus_parts: 
					if bonus == null: bonus = Globals.ResourceBonus.new()
					bonus.resource_name = bonus_parts["resource_name"]
				else:
					push_warning("bonus_parts missing resource_name")
				if "bonus" in bonus_parts: 
					bonus.bonus = bonus_parts["bonus"]
				else:
					push_warning("bonus_parts missing bonus")
				knowledge_part.bonuses.append(bonus)
		parsed_parts.append(knowledge_part)
	return parsed_parts

func _parse_knowledge_file(file_path) -> Array:
	var json_data = _read_json_from_file(file_path)
	if "knowledge" in json_data:
		return _parse_knowledge_parts(json_data["knowledge"])
	return []

func _ready():
	if Engine.is_editor_hint(): return
	directory = directory
	_refresh_files()
	for file in files:
		var parsed_knowledge = _parse_knowledge_file(file)
		undiscovered_knowledge.append_array(parsed_knowledge)

func read():
	if undiscovered_knowledge.size() == 0:
		event_view.add_text(end_reached_message)
		return
	var knowledge_part : KnowledgePart = undiscovered_knowledge.pop_front()
	if not knowledge_part.text.is_empty():
		event_view.add_read_text(knowledge_part.text)
	for resource_quantity in knowledge_part.resources:
		inventory_manager.add(resource_quantity)
	for action_type in knowledge_part.action_unlocks:
		action_learned.emit(action_type)
	for location_action in knowledge_part.location_action_unlocks:
		location_action_learned.emit(location_action)
	for bonus in knowledge_part.bonuses:
		bonus_gained.emit(bonus)
	discovered_knowledge.append(knowledge_part)
