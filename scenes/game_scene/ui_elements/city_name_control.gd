extends Control

@export var main_ui : Control
@export var action_manager : ActionManager
@export var knowledge_manager : KnowledgeManager
@export var time_manager : TimeManager
@export var default_city_name : String = ""

func _ready():
	main_ui.hide()
	show()

func _on_name_accepted():
	var city_name = %CityNameEdit.text
	if city_name.is_empty():
		city_name = default_city_name
	action_manager.city_name = city_name
	knowledge_manager.city_name = city_name
	main_ui.show()
	hide()
	action_manager.enter_city()
	time_manager.enabled = true

func _on_city_name_accept_button_pressed():
	_on_name_accepted()
