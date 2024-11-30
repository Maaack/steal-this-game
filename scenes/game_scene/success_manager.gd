class_name SuccessManager
extends Node
@export_file("*.tscn") var main_menu_scene : String
## Optional path to an ending scene.
@export_file("*.tscn") var ending_scene : String
@export_group("Screens")
## Optional win screen to be shown after the last level is won.
@export var game_won_scene : PackedScene

@export var action_manager : ActionManager
@export var time_manager : TimeManager

func _try_connecting_signal_to_node(node : Node, signal_name : String, callable : Callable):
	if node.has_signal(signal_name) and not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func _load_main_menu():
	SceneLoader.load_scene(main_menu_scene)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _load_ending():
	if ending_scene:
		SceneLoader.load_scene(ending_scene)
	else:
		_load_main_menu()

func _load_win_screen_or_ending():
	if game_won_scene:
		var instance = game_won_scene.instantiate()
		instance.city_name = action_manager.city_name
		instance.game_time = time_manager.get_game_time()
		get_tree().current_scene.add_child(instance)
		_try_connecting_signal_to_node(instance, &"continue_pressed", _load_ending)
		_try_connecting_signal_to_node(instance, &"main_menu_pressed", _load_main_menu)
	else:
		_load_ending()

func _on_level_won():
	_load_win_screen_or_ending()

func _ready():
	action_manager.city_liberated.connect(_on_level_won)
