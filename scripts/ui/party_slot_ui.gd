extends PanelContainer

signal slot_focused(index: int)

@onready var sprite: TextureRect = $HBox/Sprite
@onready var name_label: Label = $HBox/InfoVBox/NameLabel
@onready var level_label: Label = $HBox/InfoVBox/LevelStatus/LevelLabel
@onready var status_label: Label = $HBox/InfoVBox/LevelStatus/StatusLabel
@onready var hp_bar: Control = $HBox/InfoVBox/HPBar

var _index: int = 0
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat

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
	focus_mode = Control.FOCUS_ALL
	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.12, 0.12, 0.15, 0.9)
	_normal_style.set_border_width_all(1)
	_normal_style.border_color = Color(0.3, 0.3, 0.35)
	_normal_style.set_corner_radius_all(3)
	_normal_style.set_content_margin_all(4)

	_selected_style = StyleBoxFlat.new()
	_selected_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	_selected_style.set_border_width_all(2)
	_selected_style.border_color = Color(0.9, 0.7, 0.2)
	_selected_style.set_corner_radius_all(3)
	_selected_style.set_content_margin_all(4)

	add_theme_stylebox_override("panel", _normal_style)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func setup(monster: MonsterInstance, index: int) -> void:
	_index = index
	var data: Resource = monster.base_data
	if not data:
		return

	var front_tex = data.get("front_sprite")
	if front_tex and sprite:
		sprite.texture = front_tex

	if name_label:
		name_label.text = str(data.get("monster_name"))

	if level_label:
		level_label.text = "Lv.%d" % monster.level

	if status_label:
		if monster.is_fainted():
			status_label.text = "FNT"
			status_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
			status_label.visible = true
		elif monster.has_status():
			var abbrev: String = STATUS_ABBREV.get(monster.status, "")
			status_label.text = abbrev
			status_label.add_theme_color_override("font_color", STATUS_COLORS.get(monster.status, Color.WHITE))
			status_label.visible = abbrev != ""
		else:
			status_label.visible = false

	if hp_bar:
		hp_bar.setup(monster.current_hp, monster.get_max_hp())

func set_selected(selected: bool) -> void:
	if selected:
		add_theme_stylebox_override("panel", _selected_style)
	else:
		add_theme_stylebox_override("panel", _normal_style)

func _on_focus_entered() -> void:
	set_selected(true)
	slot_focused.emit(_index)

func _on_focus_exited() -> void:
	set_selected(false)
