extends PanelContainer

signal dialogue_finished
signal dialogue_action(action_string: String)

@onready var speaker_label: Label = $MarginContainer/VBox/SpeakerLabel
@onready var text_label: RichTextLabel = $MarginContainer/VBox/TextLabel
@onready var continue_indicator: Label = $MarginContainer/VBox/ContinueIndicator
@onready var choices_container: VBoxContainer = $MarginContainer/VBox/ChoicesContainer

var _nodes: Array = []
var _node_map: Dictionary = {}  # id → index
var _current_index: int = 0
var _current_char_index: float = 0.0
var _is_typing: bool = false
var _full_text: String = ""
var _has_choices: bool = false

const TYPE_SPEED := 0.03

func _ready() -> void:
	GameManager.is_in_dialogue = true
	if continue_indicator:
		continue_indicator.visible = false
	if choices_container:
		choices_container.visible = false
	if _nodes.size() > 0:
		_show_node(_current_index)

func set_tree(nodes: Array) -> void:
	_nodes = []
	_node_map = {}
	# Filter by conditions and build node list
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		if node.has("condition") and not _check_condition(node["condition"]):
			continue
		var idx: int = _nodes.size()
		_nodes.append(node)
		if node.has("id"):
			_node_map[node["id"]] = idx
	_current_index = 0

func _show_node(index: int) -> void:
	if index < 0 or index >= _nodes.size():
		_close()
		return
	_current_index = index
	var node: Dictionary = _nodes[index]

	# Speaker
	if speaker_label:
		if node.has("speaker"):
			speaker_label.text = str(node["speaker"])
			speaker_label.visible = true
		else:
			speaker_label.visible = false

	# Text
	_full_text = str(node.get("text", ""))
	_current_char_index = 0.0
	_is_typing = true
	_has_choices = false
	if text_label:
		text_label.text = ""
	if continue_indicator:
		continue_indicator.visible = false
	if choices_container:
		choices_container.visible = false
		for child in choices_container.get_children():
			child.queue_free()

	# Emit action if present
	if node.has("action"):
		dialogue_action.emit(str(node["action"]))

func _process(delta: float) -> void:
	if _is_typing:
		_current_char_index += delta / TYPE_SPEED
		var chars_to_show := int(_current_char_index)
		if chars_to_show >= _full_text.length():
			if text_label:
				text_label.text = _full_text
			_is_typing = false
			_on_typing_done()
		else:
			if text_label:
				text_label.text = _full_text.substr(0, chars_to_show)

func _on_typing_done() -> void:
	var node: Dictionary = _nodes[_current_index]
	if node.has("choices") and node["choices"] is Array and node["choices"].size() > 0:
		_show_choices(node["choices"])
	else:
		if continue_indicator:
			continue_indicator.visible = true

func _show_choices(choices: Array) -> void:
	_has_choices = true
	if not choices_container:
		return
	choices_container.visible = true
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = str(choice.get("label", "..."))
		btn.pressed.connect(_on_choice_selected.bind(str(choice.get("next", ""))))
		choices_container.add_child(btn)
	# Focus first button
	await get_tree().process_frame
	if choices_container.get_child_count() > 0:
		choices_container.get_child(0).grab_focus()

func _on_choice_selected(next_id: String) -> void:
	if _node_map.has(next_id):
		_show_node(_node_map[next_id])
	else:
		_close()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm"):
		if _is_typing:
			# Skip to full text
			if text_label:
				text_label.text = _full_text
			_is_typing = false
			_on_typing_done()
		elif not _has_choices:
			# Advance to next node
			_current_index += 1
			if _current_index >= _nodes.size():
				_close()
			else:
				_show_node(_current_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if not _has_choices:
			_close()
			get_viewport().set_input_as_handled()

func _check_condition(condition: String) -> bool:
	var parts: PackedStringArray = condition.split(":")
	if parts.size() < 2:
		return false
	var cond_type: String = parts[0]
	var cond_value: String = parts[1]
	match cond_type:
		"has_badge":
			return GameManager.has_badge(cond_value)
		"quest_active":
			return GameManager.is_quest_active(cond_value)
		"quest_complete":
			return GameManager.is_quest_complete(cond_value)
	return false

func _close() -> void:
	GameManager.is_in_dialogue = false
	dialogue_finished.emit()
	queue_free()
