@tool
class_name ActionButton
extends Button

@export var wait_time : float = 1.0 :
	set(value):
		wait_time = value

var time_left : float = 0.0

func _on_button_pressed():
	disabled = true
	time_left = wait_time

func get_progress() -> float:
	var progress : float = 1.0
	if not (is_zero_approx(time_left) or is_zero_approx(wait_time)):
		progress -= time_left/wait_time
	return progress

func _process(delta):
	%ProgressBar.value = 1.0 - get_progress()

func tick(delta: float):
	if time_left <= 0: return
	time_left -= min(time_left, delta)
	if is_zero_approx(time_left):
		disabled = false

func _ready():
	pressed.connect(_on_button_pressed)
