extends Control

signal monster_chosen(party_index: int)
signal cancelled

var _wild_monster_data: Resource  # MonsterData

@onready var message_label: Label = $HBox/LeftPanel/Message
@onready var enemy_sprite: TextureRect = $HBox/LeftPanel/EnemySprite
@onready var party_list: VBoxContainer = $HBox/RightPanel/MarginContainer/VBox/PartyList

var _buttons: Array[Button] = []

func _ready() -> void:
	GameManager.is_in_dialogue = true
	_build_ui()

func setup(wild_data: Resource) -> void:
	_wild_monster_data = wild_data

func _build_ui() -> void:
	if not _wild_monster_data:
		return

	var wild_name: String = str(_wild_monster_data.get("monster_name"))
	message_label.text = "A wild %s appeared!\nChoose your monster:" % wild_name

	var front_tex = _wild_monster_data.get("front_sprite")
	if front_tex:
		enemy_sprite.texture = front_tex

	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()

	for i in GameManager.player_party.size():
		var monster: MonsterInstance = GameManager.player_party[i]
		var data: Resource = monster.base_data
		var btn := Button.new()
		var fainted_text := ""
		if monster.is_fainted():
			fainted_text = " [FAINTED]"
			btn.disabled = true
		btn.text = "%s  Lv.%d  HP:%d/%d%s" % [
			str(data.get("monster_name")),
			monster.level,
			monster.current_hp,
			monster.get_max_hp(),
			fainted_text
		]
		btn.pressed.connect(_on_monster_picked.bind(i))
		party_list.add_child(btn)
		_buttons.append(btn)

	for btn in _buttons:
		if not btn.disabled:
			btn.call_deferred("grab_focus")
			break

func _on_monster_picked(index: int) -> void:
	GameManager.is_in_dialogue = false
	monster_chosen.emit(index)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.is_in_dialogue = false
		cancelled.emit()
		queue_free()
		get_viewport().set_input_as_handled()
