extends CanvasLayer

@onready var main_panel: PanelContainer = $MainPanel
@onready var large_sprite: TextureRect = $MainPanel/MarginContainer/HBox/LeftColumn/LargeSprite
@onready var detail_name: Label = $MainPanel/MarginContainer/HBox/LeftColumn/DetailName
@onready var detail_type: Label = $MainPanel/MarginContainer/HBox/LeftColumn/DetailType
@onready var detail_level: Label = $MainPanel/MarginContainer/HBox/LeftColumn/DetailLevel
@onready var hp_bar_container: Control = $MainPanel/MarginContainer/HBox/LeftColumn/HPBarContainer
@onready var xp_bar_container: Control = $MainPanel/MarginContainer/HBox/LeftColumn/XPBarContainer
@onready var detail_status: Label = $MainPanel/MarginContainer/HBox/LeftColumn/DetailStatus
@onready var tab_header: HBoxContainer = $MainPanel/MarginContainer/HBox/RightColumn/TabHeader
@onready var stats_panel: VBoxContainer = $MainPanel/MarginContainer/HBox/RightColumn/StatsPanel
@onready var moves_panel: VBoxContainer = $MainPanel/MarginContainer/HBox/RightColumn/MovesPanel
@onready var exp_panel: VBoxContainer = $MainPanel/MarginContainer/HBox/RightColumn/ExpPanel
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _current_tab: int = 0
var _tab_labels: Array[Label] = []
var _hp_bar: Control = null
var _xp_bar: Control = null
var _monster: MonsterInstance = null

const TAB_NAMES := ["Stats", "Moves", "EXP"]

const TYPE_COLORS: Dictionary = {
	"Fire": Color(1.0, 0.4, 0.2),
	"Water": Color(0.3, 0.5, 1.0),
	"Grass": Color(0.3, 0.8, 0.3),
	"Electric": Color(1.0, 0.85, 0.2),
	"Wind": Color(0.6, 0.85, 0.8),
	"Rock": Color(0.7, 0.6, 0.4),
	"Ice": Color(0.5, 0.85, 1.0),
	"Dark": Color(0.5, 0.3, 0.6),
	"Poison": Color(0.7, 0.3, 0.8),
	"Normal": Color(0.7, 0.7, 0.7),
}

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
	# Instance HP bar
	var hp_scene := load("res://scenes/ui/hp_bar.tscn") as PackedScene
	if hp_scene and hp_bar_container:
		_hp_bar = hp_scene.instantiate()
		hp_bar_container.add_child(_hp_bar)

	# Instance XP bar
	var xp_scene := load("res://scenes/ui/xp_bar.tscn") as PackedScene
	if xp_scene and xp_bar_container:
		_xp_bar = xp_scene.instantiate()
		xp_bar_container.add_child(_xp_bar)

	# Build tab header
	_build_tab_header()

	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_lb", "label": "Prev Tab"},
			{"icon": "btn_rb", "label": "Next Tab"},
			{"icon": "btn_b", "label": "Back"},
		])

	_show_tab(0)

func _build_tab_header() -> void:
	if not tab_header:
		return
	for child in tab_header.get_children():
		child.queue_free()
	_tab_labels.clear()

	for i in TAB_NAMES.size():
		var lbl := Label.new()
		lbl.text = TAB_NAMES[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_header.add_child(lbl)
		_tab_labels.append(lbl)

func setup_monster(monster: MonsterInstance) -> void:
	_monster = monster
	if not monster:
		return
	var data: Resource = monster.base_data
	if not data:
		return

	# Left column
	var front_tex = data.get("front_sprite")
	if front_tex and large_sprite:
		large_sprite.texture = front_tex

	if detail_name:
		detail_name.text = str(data.get("monster_name"))

	if detail_type:
		var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
		detail_type.text = etype
		if TYPE_COLORS.has(etype):
			detail_type.add_theme_color_override("font_color", TYPE_COLORS[etype])

	if detail_level:
		detail_level.text = "Lv.%d" % monster.level

	if _hp_bar:
		_hp_bar.setup(monster.current_hp, monster.get_max_hp())

	if _xp_bar:
		_xp_bar.setup(monster.experience, monster.get_xp_threshold())

	if detail_status:
		if monster.is_fainted():
			detail_status.text = "FAINTED"
			detail_status.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
			detail_status.visible = true
		elif monster.has_status():
			var abbrev: String = STATUS_ABBREV.get(monster.status, "")
			detail_status.text = abbrev
			detail_status.add_theme_color_override("font_color", STATUS_COLORS.get(monster.status, Color.WHITE))
			detail_status.visible = abbrev != ""
		else:
			detail_status.visible = false

	# Populate tab content
	_populate_stats(monster)
	_populate_moves(monster)
	_populate_exp(monster)
	_show_tab(_current_tab)

func _populate_stats(monster: MonsterInstance) -> void:
	if not stats_panel:
		return
	for child in stats_panel.get_children():
		child.queue_free()

	var stats := [
		{"name": "ATK", "value": monster.get_attack(), "max_val": 100},
		{"name": "DEF", "value": monster.get_defense(), "max_val": 100},
		{"name": "AGI", "value": monster.get_agility(), "max_val": 100},
		{"name": "SP.ATK", "value": monster.get_sp_attack(), "max_val": 100},
		{"name": "SP.DEF", "value": monster.get_sp_defense(), "max_val": 100},
	]

	for stat in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.text = stat["name"]
		lbl.custom_minimum_size = Vector2(52, 0)
		row.add_child(lbl)

		var val_lbl := Label.new()
		val_lbl.text = str(stat["value"])
		val_lbl.custom_minimum_size = Vector2(30, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_lbl)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(80, 10)
		bar.max_value = stat["max_val"]
		bar.value = min(stat["value"], stat["max_val"])
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.6, 0.9)
		bar.add_theme_stylebox_override("fill", style)
		row.add_child(bar)

		stats_panel.add_child(row)

func _populate_moves(monster: MonsterInstance) -> void:
	if not moves_panel:
		return
	for child in moves_panel.get_children():
		child.queue_free()

	if monster.skills.is_empty():
		var lbl := Label.new()
		lbl.text = "No moves learned"
		moves_panel.add_child(lbl)
		return

	for skill in monster.skills:
		var row := PanelContainer.new()
		var stype: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
		var color: Color = TYPE_COLORS.get(stype, Color(0.7, 0.7, 0.7))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(color, 0.2)
		style.set_border_width_all(1)
		style.border_color = Color(color, 0.5)
		style.set_corner_radius_all(3)
		style.set_content_margin_all(3)
		row.add_theme_stylebox_override("panel", style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# Type badge
		var type_lbl := Label.new()
		type_lbl.text = stype
		type_lbl.add_theme_color_override("font_color", color)
		type_lbl.custom_minimum_size = Vector2(48, 0)
		hbox.add_child(type_lbl)

		# Move name
		var name_lbl := Label.new()
		name_lbl.text = str(skill.get("skill_name"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		# Power
		var pow_lbl := Label.new()
		pow_lbl.text = "Pow:%d" % int(skill.get("power"))
		hbox.add_child(pow_lbl)

		# Accuracy
		var acc_val: float = float(skill.get("accuracy")) if skill.get("accuracy") else 1.0
		var acc_lbl := Label.new()
		acc_lbl.text = "Acc:%d%%" % int(acc_val * 100)
		hbox.add_child(acc_lbl)

		row.add_child(hbox)
		moves_panel.add_child(row)

func _populate_exp(monster: MonsterInstance) -> void:
	if not exp_panel:
		return
	for child in exp_panel.get_children():
		child.queue_free()

	var xp_threshold := monster.get_xp_threshold()

	var current_lbl := Label.new()
	current_lbl.text = "Current EXP: %d" % monster.experience
	exp_panel.add_child(current_lbl)

	var next_lbl := Label.new()
	next_lbl.text = "To Next Level: %d" % max(0, xp_threshold - monster.experience)
	exp_panel.add_child(next_lbl)

	var threshold_lbl := Label.new()
	threshold_lbl.text = "Level %d Threshold: %d" % [monster.level, xp_threshold]
	exp_panel.add_child(threshold_lbl)

	# XP progress bar
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = xp_threshold if xp_threshold > 0 else 1
	bar.value = monster.experience
	bar.show_percentage = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9)
	bar.add_theme_stylebox_override("fill", style)
	exp_panel.add_child(bar)

	var growth_lbl := Label.new()
	var data: Resource = monster.base_data
	var growth_type: String = "Standard"
	if data and data.get("growth_curve"):
		growth_type = str(data.get("growth_curve"))
	growth_lbl.text = "Growth: %s" % growth_type
	exp_panel.add_child(growth_lbl)

func _show_tab(index: int) -> void:
	_current_tab = index
	if stats_panel:
		stats_panel.visible = (index == 0)
	if moves_panel:
		moves_panel.visible = (index == 1)
	if exp_panel:
		exp_panel.visible = (index == 2)

	# Highlight active tab label
	for i in _tab_labels.size():
		if i == index:
			_tab_labels[i].add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		else:
			_tab_labels[i].remove_theme_color_override("font_color")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_tab_left"):
		_current_tab = (_current_tab - 1)
		if _current_tab < 0:
			_current_tab = TAB_NAMES.size() - 1
		_show_tab(_current_tab)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_tab_right"):
		_current_tab = (_current_tab + 1) % TAB_NAMES.size()
		_show_tab(_current_tab)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
