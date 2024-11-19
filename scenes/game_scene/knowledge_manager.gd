@tool
class_name KnowledgeManager
extends DirectoryReader

@export_multiline var end_reached_message : String = ""
@export var inventory_manager : InventoryManager
@export var event_view : EventView

class KnowledgePart :
	var text : String
	var resources : Array[ResourceQuantity]

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
		parsed_parts.append(knowledge_part)
	return parsed_parts

func _parse_knowledge_file(file_path) -> Array:
	var json_data = _read_json_from_file(file_path)
	if "parts" in json_data:
		return _parse_knowledge_parts(json_data["parts"])
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
		event_view.add_event_text(end_reached_message)
		return
	var knowledge_part : KnowledgePart = undiscovered_knowledge.pop_front()
	if not knowledge_part.text.is_empty():
		event_view.add_read_text(knowledge_part.text)
	for resource_quantity in knowledge_part.resources:
		inventory_manager.add(resource_quantity)
	discovered_knowledge.append(knowledge_part)
