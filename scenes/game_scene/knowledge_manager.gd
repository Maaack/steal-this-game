@tool
class_name KnowledgeManager
extends Node

## Helper class for listing all the scenes in a directory.

## List of paths to scene files.
## Prefilled in the editor by selecting a directory.
@export var files : Array[String]
## Prefill files with any scenes in the directory.
@export_dir var directory : String :
	set(value):
		directory = value
@export_tool_button("Reload Files") var _refresh_file_action = _refresh_files
@export_multiline var end_reached_message : String = ""

var knowledge : Array = []

func _refresh_files() -> void:
	if not is_inside_tree() or directory.is_empty(): return
	var dir_access = DirAccess.open(directory)
	if dir_access:
		files.clear()
		for file in dir_access.get_files():
			if not file.ends_with(".json"):
				continue
			files.append(directory + "/" + file)

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
		if "text" in part:
			parsed_parts.append(part["text"])
	return parsed_parts

func _parse_knowledge_file(file_path) -> Array:
	var json_data = _read_json_from_file(file_path)
	if "parts" in json_data:
		return _parse_knowledge_parts(json_data["parts"])
	return []

func _ready():
	directory = directory
	for file in files:
		var parsed_knowledge = _parse_knowledge_file(file)
		knowledge.append_array(parsed_knowledge)

func get_next_knowledge() -> String:
	if knowledge.size() == 0:
		return end_reached_message
	return knowledge.pop_front()
