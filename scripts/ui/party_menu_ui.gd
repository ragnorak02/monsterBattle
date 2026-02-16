extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var party_list: VBoxContainer = $Panel/MarginContainer/VBox/PartyList
@onready var detail_panel: PanelContainer = $Panel/MarginContainer/VBox/DetailPanel
@onready var detail_sprite: TextureRect = $Panel/MarginContainer/VBox/DetailPanel/HBox/Sprite
@onready var detail_info: Label = $Panel/MarginContainer/VBox/DetailPanel/HBox/Info

var _selected_index: int = 0
var _slot_buttons: Array[Button] = []

func _ready() -> void:
	GameManager.is_in_menu = true
	_build_party_list()

func _build_party_list() -> void:
	for btn in _slot_buttons:
		btn.queue_free()
	_slot_buttons.clear()

	for i in GameManager.player_party.size():
		var monster: MonsterInstance = GameManager.player_party[i]
		var data: Resource = monster.base_data
		var btn := Button.new()
		var status := ""
		if monster.is_fainted():
			status = " [FAINTED]"
		btn.text = "%s Lv.%d  HP:%d/%d%s" % [
			str(data.get("monster_name")),
			monster.level,
			monster.current_hp,
			monster.get_max_hp(),
			status
		]
		btn.pressed.connect(_on_slot_selected.bind(i))
		btn.focus_entered.connect(_on_slot_focused.bind(i))
		party_list.add_child(btn)
		_slot_buttons.append(btn)

	if _slot_buttons.size() > 0:
		_slot_buttons[0].grab_focus()
		_show_detail(0)

func _on_slot_selected(index: int) -> void:
	_selected_index = index
	_show_detail(index)

func _on_slot_focused(index: int) -> void:
	_show_detail(index)

func _show_detail(index: int) -> void:
	if index >= GameManager.player_party.size():
		return
	var monster: MonsterInstance = GameManager.player_party[index]
	var data: Resource = monster.base_data
	var front_tex = data.get("front_sprite")
	if front_tex:
		detail_sprite.texture = front_tex

	var skills_text := ""
	for skill in monster.skills:
		skills_text += "\n  - %s (Pow:%d)" % [str(skill.get("skill_name")), int(skill.get("power"))]
	detail_info.text = "%s  Lv.%d\nHP: %d / %d\nATK: %d  DEF: %d  AGI: %d\nSkills:%s" % [
		str(data.get("monster_name")),
		monster.level,
		monster.current_hp,
		monster.get_max_hp(),
		monster.get_attack(),
		monster.get_defense(),
		monster.get_agility(),
		skills_text
	]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_menu"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
