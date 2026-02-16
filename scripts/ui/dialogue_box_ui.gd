extends PanelContainer

@onready var text_label: RichTextLabel = $MarginContainer/TextLabel
@onready var continue_indicator: Label = $MarginContainer/ContinueIndicator

var _lines: Array[String] = []
var _current_line_index: int = 0
var _current_char_index: int = 0
var _is_typing: bool = false
var _full_text: String = ""

const TYPE_SPEED := 0.03  # seconds per character

func _ready() -> void:
	GameManager.is_in_dialogue = true
	if continue_indicator:
		continue_indicator.visible = false
	if _lines.size() > 0:
		_show_line(_current_line_index)

func set_lines(lines: Array) -> void:
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	_current_line_index = 0

func _show_line(index: int) -> void:
	if index >= _lines.size():
		_close()
		return
	_full_text = _lines[index]
	_current_char_index = 0
	_is_typing = true
	text_label.text = ""
	if continue_indicator:
		continue_indicator.visible = false

func _process(delta: float) -> void:
	if _is_typing:
		_current_char_index += delta / TYPE_SPEED
		var chars_to_show := int(_current_char_index)
		if chars_to_show >= _full_text.length():
			text_label.text = _full_text
			_is_typing = false
			if continue_indicator:
				continue_indicator.visible = true
		else:
			text_label.text = _full_text.substr(0, chars_to_show)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm"):
		if _is_typing:
			# Skip to full text
			text_label.text = _full_text
			_is_typing = false
			if continue_indicator:
				continue_indicator.visible = true
		else:
			# Advance to next line
			_current_line_index += 1
			_show_line(_current_line_index)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_dialogue = false
	queue_free()
