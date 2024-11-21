@tool
class_name ActionButton
extends VBoxContainer

signal button_pressed

@export var button_text : String = "" :
	set(value):
		button_text = value
		if is_inside_tree():
			%Button.text = button_text
@export var wait_time : float = 1.0 :
	set(value):
		wait_time = value
@export var disabled : bool : 
	set(value):
		disabled = value
		if is_inside_tree():
			%Button.disabled = disabled

var time_left : float = 0.0

func _on_button_pressed():
	button_pressed.emit()
	%Button.disabled = true
	time_left = wait_time

func _on_progress_timer_timeout():
	%Button.disabled = false

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
		%Button.disabled = false

func _ready():
	button_text = button_text
	disabled = disabled
