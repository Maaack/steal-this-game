class_name EventView
extends Control

signal writing_text_finished

@export var char_wait_time: float = 0.025
@export var event_color: Color = Color.WHITE
@export var success_color: Color = Color.WHITE
@export var failure_color: Color = Color.WHITE
@export var scroll_delay : float = 0.5
@export var v_scroll_margin: float = 8.0 

@onready var rich_text_label : RichTextLabel
@onready var scroll_container : ScrollContainer = %ScrollContainer
@onready var _v_scroll : VScrollBar = %ScrollContainer.get_v_scroll_bar()
@onready var margin_container : MarginContainer = %MarginContainer
@onready var text_container : Container = %TextContainer

func _ready() -> void:
	margin_container.set("theme_override_constants/margin_right", v_scroll_margin)
	_v_scroll.connect("visibility_changed", Callable(self, "_on_scroll_bar_visibility_changed"))

func _on_scroll_bar_visibility_changed() -> void:
	pass
	if _v_scroll.visible:
		margin_container.set("theme_override_constants/margin_right", 0)
	else:
		margin_container.set("theme_override_constants/margin_right", v_scroll_margin)

func _stop_writing_text():
	emit_signal("writing_text_finished")

func _write_out_line():
	rich_text_label.visible_characters = 0
	while rich_text_label.visible_ratio < 1.0:
		var char_timer = get_tree().create_timer(char_wait_time)
		await char_timer.timeout
		rich_text_label.visible_characters += 1
	_stop_writing_text()

func _scroll_down_to_text():
	var height : float = rich_text_label.size.y
	height += scroll_container.scroll_vertical
	var tween = create_tween()
	tween.tween_property(scroll_container, "scroll_vertical", height, scroll_delay)

func advance_buffer_text():
	if rich_text_label and rich_text_label.visible_ratio < 1.0:
		rich_text_label.visible_ratio = 1.0
		_stop_writing_text()
	rich_text_label = RichTextLabel.new()
	rich_text_label.scroll_active = false
	rich_text_label.fit_content = true
	rich_text_label.bbcode_enabled = true
	rich_text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	text_container.add_child(rich_text_label)
	_scroll_down_to_text.call_deferred()

func add_text(value : String):
	if value.is_empty(): return
	advance_buffer_text()
	rich_text_label.text = "%s\n" % value
	_write_out_line()

func add_quantity(quantity_name : String, delta : float, good : bool = true):
	advance_buffer_text()
	if (delta > 0 and good) or (delta < 0 and not good):
		rich_text_label.text = "%s [color=#%s][b]%+.0f[/b][/color]\n" % [quantity_name.capitalize(), success_color.to_html(false), delta]
	else:
		rich_text_label.text = "%s [color=#%s][b]%.0f[/b][/color]\n" % [quantity_name.capitalize(), failure_color.to_html(false), delta]
	_write_out_line()

func add_failure_text(value : String):
	advance_buffer_text()
	rich_text_label.text = "[color=#%s][b]Failure: [/b][/color]%s\n" % [failure_color.to_html(false), value]
	_write_out_line()

func add_success_text(value : String):
	advance_buffer_text()
	rich_text_label.text = "[color=#%s][b]Success: [/b][/color]%s\n" % [success_color.to_html(false), value]
	_write_out_line()

func add_read_text(value : String):
	advance_buffer_text()
	rich_text_label.text = "[center][i]%s[/i][center]\n" % value
	_write_out_line()

func add_discovered_text(value : String, type : String = ""):
	advance_buffer_text()
	if not type.is_empty():
		type = "[/b] (%s)[b]" % type
	rich_text_label.text = "[color=#%s][b]Discovered%s: [/b][/color]%s\n" % [success_color.to_html(false), type, value]
	_write_out_line()

func add_event_title(value : String):
	advance_buffer_text()
	rich_text_label.text += "[color=#%s][b]%s[/b][/color]\n" % [event_color.to_html(false), value]
	_write_out_line()
