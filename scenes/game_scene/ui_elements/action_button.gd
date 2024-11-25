@tool
class_name ActionButton
extends Button

signal wait_time_passed

@export var wait_time : float = 1.0 :
	set(value):
		wait_time = value

var wait_time_left : float = 0.0
var waiting : bool = false

func wait(time):
	if is_zero_approx(time): return
	wait_time = time
	wait_time_left = wait_time
	waiting = true
	theme_type_variation = &"WaitingButton"

func get_progress() -> float:
	var progress : float = 1.0
	if not (is_zero_approx(wait_time_left) or is_zero_approx(wait_time)):
		progress -= wait_time_left/wait_time
	return progress

func _process(delta):
	%ProgressBar.value = 1.0 - get_progress()

func tick(delta: float):
	if wait_time_left <= 0: return
	wait_time_left -= min(wait_time_left, delta)
	if is_zero_approx(wait_time_left):
		wait_time_passed.emit()
		waiting = false
		theme_type_variation = &""

func _on_mouse_entered():
	%ProgressBar.theme_type_variation = &"ProgressBarDelayHovered"

func _on_mouse_exited():
	%ProgressBar.theme_type_variation = &"ProgressBarDelay"

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
