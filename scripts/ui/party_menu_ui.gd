extends CanvasLayer

const PartySlotScene := preload("res://scenes/ui/party_slot.tscn")
const HPBarScene := preload("res://scenes/ui/hp_bar.tscn")

@onready var main_panel: PanelContainer = $MainPanel
@onready var active_sprite: TextureRect = $MainPanel/MarginContainer/HBox/LeftPanel/ActiveSprite
@onready var name_label: Label = $MainPanel/MarginContainer/HBox/LeftPanel/NameLabel
@onready var type_label: Label = $MainPanel/MarginContainer/HBox/LeftPanel/TypeLabel
@onready var level_label: Label = $MainPanel/MarginContainer/HBox/LeftPanel/LevelLabel
@onready var hp_bar_placeholder: Control = $MainPanel/MarginContainer/HBox/LeftPanel/HPBar
@onready var status_label: Label = $MainPanel/MarginContainer/HBox/LeftPanel/StatusLabel
@onready var trainer_header: Label = $MainPanel/MarginContainer/HBox/RightPanel/TrainerHeader
@onready var party_list: VBoxContainer = $MainPanel/MarginContainer/HBox/RightPanel/PartyList
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _selected_index: int = 0
var _slot_nodes: Array = []
var _hp_bar: Control = null
var _detail_open: bool = false

const STATUS_COLORS: Dictionary = {
	"poison": Color(0.7, 0.3, 0.8),
	"burn": Color(1.0, 0.4, 0.2),
	"paralysis": Color(1.0, 0.85, 0.2),
}

const STATUS_ABBREV: Dictionary = {
	"poison": "PSN",
	"burn": "BRN",
	"paralysis": "PAR",
}

func _ready() -> void:
	GameManager.is_in_menu = true
	AudioManager.play_sfx(AssetRegistry.sfx_menu_open)

	# Instance HP bar into placeholder
	_hp_bar = HPBarScene.instantiate()
	hp_bar_placeholder.add_child(_hp_bar)

	# Set trainer header
	if trainer_header:
		trainer_header.text = "%s (Rank %d)" % [GameManager.get_trainer_title(), GameManager.trainer_rank]

	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_a", "label": "Detail"},
			{"icon": "btn_b", "label": "Close"},
			{"icon": "dpad", "label": "Navigate"},
		])

	_build_party_list()

	# Slide-in animation
	if main_panel:
		var target_pos := main_panel.position
		main_panel.position.x += 600
		var tween := create_tween()
		tween.tween_property(main_panel, "position:x", target_pos.x, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _build_party_list() -> void:
	for node in _slot_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_slot_nodes.clear()

	for i in GameManager.player_party.size():
		var monster: MonsterInstance = GameManager.player_party[i]
		var slot: PanelContainer = PartySlotScene.instantiate()
		party_list.add_child(slot)
		slot.setup(monster, i)
		slot.slot_focused.connect(_on_slot_focused)

		# Set up focus neighbors for vertical navigation
		_slot_nodes.append(slot)

	# Connect focus neighbors
	for i in _slot_nodes.size():
		var slot: Control = _slot_nodes[i]
		if i > 0:
			slot.focus_neighbor_top = _slot_nodes[i - 1].get_path()
		if i < _slot_nodes.size() - 1:
			slot.focus_neighbor_bottom = _slot_nodes[i + 1].get_path()

	# Wrap around
	if _slot_nodes.size() > 1:
		_slot_nodes[0].focus_neighbor_top = _slot_nodes[_slot_nodes.size() - 1].get_path()
		_slot_nodes[_slot_nodes.size() - 1].focus_neighbor_bottom = _slot_nodes[0].get_path()

	if _slot_nodes.size() > 0:
		_slot_nodes[0].call_deferred("grab_focus")
		_update_left_panel(0)

func _on_slot_focused(index: int) -> void:
	_selected_index = index
	_update_left_panel(index)

func _update_left_panel(index: int) -> void:
	if index >= GameManager.player_party.size():
		return
	var monster: MonsterInstance = GameManager.player_party[index]
	var data: Resource = monster.base_data
	if not data:
		return

	var front_tex = data.get("front_sprite")
	if front_tex and active_sprite:
		active_sprite.texture = front_tex

	if name_label:
		name_label.text = str(data.get("monster_name"))

	if type_label:
		var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
		type_label.text = etype

	if level_label:
		level_label.text = "Lv.%d" % monster.level

	if _hp_bar:
		_hp_bar.setup(monster.current_hp, monster.get_max_hp())

	if status_label:
		if monster.is_fainted():
			status_label.text = "FAINTED"
			status_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
			status_label.visible = true
		elif monster.has_status():
			var abbrev: String = STATUS_ABBREV.get(monster.status, "")
			status_label.text = abbrev
			status_label.add_theme_color_override("font_color", STATUS_COLORS.get(monster.status, Color.WHITE))
			status_label.visible = abbrev != ""
		else:
			status_label.text = ""
			status_label.visible = false

func _input(event: InputEvent) -> void:
	if _detail_open:
		return
	if event.is_action_pressed("ui_accept"):
		_open_detail(_selected_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_menu"):
		_close()
		get_viewport().set_input_as_handled()

func _open_detail(index: int) -> void:
	if index >= GameManager.player_party.size():
		return
	_detail_open = true
	var detail_scene := load("res://scenes/ui/monster_detail.tscn") as PackedScene
	if not detail_scene:
		_detail_open = false
		return
	var detail: CanvasLayer = detail_scene.instantiate()
	get_parent().add_child(detail)
	detail.setup_monster(GameManager.player_party[index])
	detail.tree_exiting.connect(_on_detail_closed)

func _on_detail_closed() -> void:
	_detail_open = false
	if _selected_index < _slot_nodes.size() and is_instance_valid(_slot_nodes[_selected_index]):
		_slot_nodes[_selected_index].call_deferred("grab_focus")

func _close() -> void:
	AudioManager.play_sfx(AssetRegistry.sfx_menu_close)
	GameManager.is_in_menu = false
	# Slide-out animation (reverse of slide-in)
	if main_panel:
		var tween := create_tween()
		tween.tween_property(main_panel, "position:x", main_panel.position.x + 600, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
	queue_free()
