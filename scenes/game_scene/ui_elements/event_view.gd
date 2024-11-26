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

var original_margin_right : float

func _ready() -> void:
	original_margin_right = margin_container.get("theme_override_constants/margin_right") or 0.0
	margin_container.set("theme_override_constants/margin_right", original_margin_right + v_scroll_margin)
	_v_scroll.connect("visibility_changed", Callable(self, "_on_scroll_bar_visibility_changed"))

func _on_scroll_bar_visibility_changed() -> void:
	if _v_scroll.visible:
		margin_container.set("theme_override_constants/margin_right", original_margin_right)
	else:
		margin_container.set("theme_override_constants/margin_right", original_margin_right + v_scroll_margin)

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

func _set_rich_text_label():
	if rich_text_label: return 
	rich_text_label = RichTextLabel.new()
	rich_text_label.scroll_active = false
	rich_text_label.fit_content = true
	rich_text_label.bbcode_enabled = true
	rich_text_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	text_container.add_child(rich_text_label)
	_scroll_down_to_text.call_deferred()

func advance_buffer_text():
	if rich_text_label and rich_text_label.visible_ratio < 1.0:
		rich_text_label.visible_ratio = 1.0
		_stop_writing_text()
	rich_text_label = null
	_set_rich_text_label()

func add_text(value : String):
	if value.is_empty(): return
	advance_buffer_text()
	rich_text_label.text = "%s\n" % value
	_write_out_line()

func add_quantity_text(quantity : ResourceQuantity, good : bool = true):
	_set_rich_text_label()
	var color_string : String
	if (quantity.quantity > 0 and good) or (quantity.quantity < 0 and not good):
		color_string = success_color.to_html(false)
	else:
		color_string = failure_color.to_html(false)
	var delta_string : String = "[color=#%s][b]%+.0f[/b][/color]" % [color_string, quantity.quantity]
	if quantity is ResourceBonusQuantity:
		var multi_color_string : String
		if quantity.multiplier > 1.0:
			multi_color_string = success_color.to_html(false)
		elif  quantity.multiplier < 1.0:
			multi_color_string = failure_color.to_html(false)
		var multi_string : String = "[color=#%s]%.2f[/color]" % [multi_color_string, quantity.multiplier]
		delta_string = "[color=#%s]%+.0f[/color] x %s = [color=#%s][b]%+.0f[/b][/color]" % [color_string, quantity.get_raw_quantity(), multi_string, color_string, quantity.quantity]
	rich_text_label.text += "%s %s\n" % [quantity.name.capitalize(), delta_string]
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
	rich_text_label.text = "\n[center]%s[/center]\n\n" % value
	_write_out_line()

func add_discovered_text(value : String, type : String = "", is_new: bool = true):
	if is_new:
		advance_buffer_text()
	else:
		_set_rich_text_label()
	if not type.is_empty():
		type = "[/b] (%s)[b]" % type
	rich_text_label.text += "[color=#%s][b]Discovered%s: [/b][/color]%s\n" % [success_color.to_html(false), type, value]
	_write_out_line()

func add_bonus_text(value : String, bonus : float, good: bool = true):
	_set_rich_text_label()
	rich_text_label.text += "[color=#%s][b]Discovered[/b] (Bonus)[b]: [/b][/color]" % success_color.to_html(false)
	var color_string : String
	if (bonus > 0 and good) or (bonus < 0 and not good):
		color_string = success_color.to_html(false)
	else:
		color_string = failure_color.to_html(false)
	rich_text_label.text += "%s [color=#%s][b]%+.f%%[/b][/color]\n" % [value, color_string, bonus * 100]
	_write_out_line()

func add_event_title(value : String):
	advance_buffer_text()
	rich_text_label.text += "[color=#%s][b]%s[/b][/color]\n" % [event_color.to_html(false), value]
	_write_out_line()
