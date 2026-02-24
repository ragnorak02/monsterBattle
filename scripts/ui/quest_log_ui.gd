extends CanvasLayer

@onready var quest_list: VBoxContainer = $Panel/MarginContainer/VBox/QuestList
@onready var detail_label: Label = $Panel/MarginContainer/VBox/DetailLabel
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _quest_buttons: Array[Button] = []

func _ready() -> void:
	GameManager.is_in_menu = true
	_build_quest_list()
	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_b", "label": "Close"},
			{"icon": "dpad", "label": "Navigate"},
		])

func _build_quest_list() -> void:
	for btn in _quest_buttons:
		btn.queue_free()
	_quest_buttons.clear()

	var has_quests := false

	# Active quests
	for quest_id: String in GameManager.active_quests:
		has_quests = true
		var quest_def: Dictionary = GameManager.get_quest_def(quest_id)
		var progress: int = GameManager.get_quest_progress(quest_id)
		var goal: int = int(quest_def.get("goal", 1))
		var btn := Button.new()
		btn.text = "%s (%d/%d)" % [quest_def.get("name", quest_id), progress, goal]
		btn.focus_entered.connect(_on_quest_focused.bind(quest_id, false))
		quest_list.add_child(btn)
		_quest_buttons.append(btn)

	# Completed quests (greyed out)
	for quest_id: String in GameManager.completed_quests:
		has_quests = true
		var quest_def: Dictionary = GameManager.get_quest_def(quest_id)
		var btn := Button.new()
		btn.text = "[Done] %s" % quest_def.get("name", quest_id)
		btn.modulate = Color(0.5, 0.5, 0.5)
		btn.focus_entered.connect(_on_quest_focused.bind(quest_id, true))
		quest_list.add_child(btn)
		_quest_buttons.append(btn)

	if not has_quests:
		detail_label.text = "No quests yet."
	elif _quest_buttons.size() > 0:
		_quest_buttons[0].grab_focus()
		# Show first quest details
		var first_id: String = ""
		if GameManager.active_quests.size() > 0:
			first_id = GameManager.active_quests.keys()[0]
		elif GameManager.completed_quests.size() > 0:
			first_id = GameManager.completed_quests.keys()[0]
		if first_id != "":
			_show_quest_detail(first_id, GameManager.is_quest_complete(first_id))

func _on_quest_focused(quest_id: String, is_complete: bool) -> void:
	_show_quest_detail(quest_id, is_complete)

func _show_quest_detail(quest_id: String, is_complete: bool) -> void:
	var quest_def: Dictionary = GameManager.get_quest_def(quest_id)
	if quest_def.is_empty():
		return
	var desc: String = str(quest_def.get("description", ""))
	if is_complete:
		detail_label.text = "%s\n[Completed]" % desc
	else:
		var progress: int = GameManager.get_quest_progress(quest_id)
		var goal: int = int(quest_def.get("goal", 1))
		detail_label.text = "%s\nProgress: %d/%d" % [desc, progress, goal]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
