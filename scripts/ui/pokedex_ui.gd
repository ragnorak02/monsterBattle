extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var counter_label: Label = $Panel/MarginContainer/VBox/Counter
@onready var monster_list: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/MonsterList
@onready var detail_sprite: TextureRect = $Panel/MarginContainer/VBox/DetailPanel/HBox/Sprite
@onready var detail_info: Label = $Panel/MarginContainer/VBox/DetailPanel/HBox/Info
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _slot_buttons: Array[Button] = []
var _monster_ids: Array[int] = []

func _ready() -> void:
	GameManager.is_in_menu = true
	_build_list()
	if hint_bar:
		hint_bar.set_hints([
			{"icon": "dpad", "label": "Navigate"},
			{"icon": "btn_b", "label": "Close"},
		])

func _build_list() -> void:
	for btn in _slot_buttons:
		btn.queue_free()
	_slot_buttons.clear()
	_monster_ids.clear()

	var seen_count: int = GameManager.get_seen_count()
	var caught_count: int = GameManager.get_caught_count()
	var total_count: int = GameManager.get_total_monster_count()
	counter_label.text = "Seen: %d   Caught: %d   Total: %d" % [seen_count, caught_count, total_count]

	var ids: Array = MonsterDB.monsters.keys()
	ids.sort()
	for id: int in ids:
		_monster_ids.append(id)
		var btn := Button.new()
		if GameManager.is_monster_caught(id):
			var data: Resource = MonsterDB.monsters[id]
			btn.text = "#%03d %s [CAUGHT]" % [id, str(data.get("monster_name"))]
		elif GameManager.is_monster_seen(id):
			var data: Resource = MonsterDB.monsters[id]
			btn.text = "#%03d %s [SEEN]" % [id, str(data.get("monster_name"))]
		else:
			btn.text = "#%03d ???" % id
		var idx: int = _slot_buttons.size()
		btn.focus_entered.connect(_on_slot_focused.bind(idx))
		monster_list.add_child(btn)
		_slot_buttons.append(btn)

	if _slot_buttons.size() > 0:
		_slot_buttons[0].grab_focus()
		_show_detail(0)

func _on_slot_focused(index: int) -> void:
	_show_detail(index)

func _show_detail(index: int) -> void:
	if index < 0 or index >= _monster_ids.size():
		return
	var id: int = _monster_ids[index]

	if GameManager.is_monster_caught(id):
		var data: Resource = MonsterDB.monsters[id]
		var front_tex = data.get("front_sprite")
		if front_tex:
			detail_sprite.texture = front_tex as Texture2D
		else:
			detail_sprite.texture = null
		var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
		detail_info.text = "%s [%s]\nHP: %d  ATK: %d  DEF: %d\nAGI: %d  SpA: %d  SpD: %d" % [
			str(data.get("monster_name")),
			etype,
			int(data.get("max_hp")),
			int(data.get("attack")),
			int(data.get("defense")),
			int(data.get("agility")),
			int(data.get("sp_attack")) if data.get("sp_attack") else 0,
			int(data.get("sp_defense")) if data.get("sp_defense") else 0,
		]
	elif GameManager.is_monster_seen(id):
		var data: Resource = MonsterDB.monsters[id]
		var front_tex = data.get("front_sprite")
		if front_tex:
			detail_sprite.texture = front_tex as Texture2D
		else:
			detail_sprite.texture = null
		var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
		detail_info.text = "%s [%s]\n???" % [str(data.get("monster_name")), etype]
	else:
		detail_sprite.texture = null
		detail_info.text = "No data"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
