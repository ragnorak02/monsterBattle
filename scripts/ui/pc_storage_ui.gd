extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var party_label: Label = $Panel/MarginContainer/VBox/Columns/PartyColumn/PartyLabel
@onready var party_list: VBoxContainer = $Panel/MarginContainer/VBox/Columns/PartyColumn/PartyList
@onready var pc_label: Label = $Panel/MarginContainer/VBox/Columns/PCColumn/PCLabel
@onready var pc_list: VBoxContainer = $Panel/MarginContainer/VBox/Columns/PCColumn/PCList
@onready var detail_sprite: TextureRect = $Panel/MarginContainer/VBox/DetailPanel/HBox/Sprite
@onready var detail_info: Label = $Panel/MarginContainer/VBox/DetailPanel/HBox/Info
@onready var feedback_label: Label = $Panel/MarginContainer/VBox/FeedbackLabel
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _party_buttons: Array[Button] = []
var _pc_buttons: Array[Button] = []
var _in_party_column: bool = true

func _ready() -> void:
	GameManager.is_in_menu = true
	_build_lists()
	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_a", "label": "Move"},
			{"icon": "btn_b", "label": "Close"},
			{"icon": "btn_lb", "label": "Party"},
			{"icon": "btn_rb", "label": "PC"},
		])

func _build_lists() -> void:
	_clear_buttons()
	_build_party_list()
	_build_pc_list()
	_grab_initial_focus()

func _clear_buttons() -> void:
	for btn in _party_buttons:
		btn.queue_free()
	_party_buttons.clear()
	for btn in _pc_buttons:
		btn.queue_free()
	_pc_buttons.clear()

func _build_party_list() -> void:
	party_label.text = "Party (%d/6)" % GameManager.player_party.size()
	for i in GameManager.player_party.size():
		var monster: MonsterInstance = GameManager.player_party[i]
		var btn := Button.new()
		var status := ""
		if monster.is_fainted():
			status = " [FNT]"
		btn.text = "%s Lv.%d%s" % [str(monster.base_data.get("monster_name")), monster.level, status]
		btn.pressed.connect(_on_party_selected.bind(i))
		btn.focus_entered.connect(_on_slot_focused.bind(monster))
		party_list.add_child(btn)
		_party_buttons.append(btn)

func _build_pc_list() -> void:
	pc_label.text = "PC (%d stored)" % GameManager.pc_storage.size()
	for i in GameManager.pc_storage.size():
		var monster: MonsterInstance = GameManager.pc_storage[i]
		var btn := Button.new()
		var status := ""
		if monster.is_fainted():
			status = " [FNT]"
		btn.text = "%s Lv.%d%s" % [str(monster.base_data.get("monster_name")), monster.level, status]
		btn.pressed.connect(_on_pc_selected.bind(i))
		btn.focus_entered.connect(_on_slot_focused.bind(monster))
		pc_list.add_child(btn)
		_pc_buttons.append(btn)
	if _pc_buttons.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		pc_list.add_child(empty_label)

func _grab_initial_focus() -> void:
	if _in_party_column and _party_buttons.size() > 0:
		_party_buttons[0].grab_focus()
		_show_detail(_party_buttons[0], GameManager.player_party[0])
	elif _pc_buttons.size() > 0:
		_pc_buttons[0].grab_focus()
		_show_detail(_pc_buttons[0], GameManager.pc_storage[0])

func _on_party_selected(index: int) -> void:
	_in_party_column = true
	if not GameManager.move_party_to_pc(index):
		_show_feedback("Can't deposit your last monster!")
		return
	_show_feedback("Moved to PC!")
	_rebuild()

func _on_pc_selected(index: int) -> void:
	_in_party_column = false
	if not GameManager.move_pc_to_party(index):
		_show_feedback("Party is full!")
		return
	_show_feedback("Moved to party!")
	_rebuild()

func _on_slot_focused(monster: MonsterInstance) -> void:
	_show_detail(null, monster)

func _show_detail(_btn: Variant, monster: MonsterInstance) -> void:
	var data: Resource = monster.base_data
	var front_tex = data.get("front_sprite")
	if front_tex:
		detail_sprite.texture = front_tex
	else:
		detail_sprite.texture = null

	var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
	detail_info.text = "%s [%s] Lv.%d\nHP: %d/%d  ATK: %d  DEF: %d" % [
		str(data.get("monster_name")),
		etype,
		monster.level,
		monster.current_hp,
		monster.get_max_hp(),
		monster.get_attack(),
		monster.get_defense(),
	]

func _show_feedback(msg: String) -> void:
	if feedback_label:
		feedback_label.text = msg
		feedback_label.modulate = Color(1, 1, 1, 1)
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5)

func _rebuild() -> void:
	_build_lists()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	# LB/RB to switch columns
	if event.is_action_pressed("ui_tab_left"):
		_in_party_column = true
		if _party_buttons.size() > 0:
			_party_buttons[0].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_tab_right"):
		_in_party_column = false
		if _pc_buttons.size() > 0:
			_pc_buttons[0].grab_focus()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
