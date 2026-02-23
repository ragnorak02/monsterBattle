extends Control

@onready var sprite: TextureRect = $VBox/Sprite
@onready var name_label: Label = $VBox/InfoBox/NameLabel
@onready var level_label: Label = $VBox/InfoBox/LevelLabel
@onready var hp_bar: Control = $VBox/InfoBox/HPBar
@onready var status_label: Label = $VBox/InfoBox/StatusLabel

var _monster: MonsterInstance

const STATUS_COLORS: Dictionary = {
	"poison": Color(0.7, 0.3, 0.9),
	"burn": Color(1.0, 0.4, 0.2),
	"paralysis": Color(1.0, 0.85, 0.2),
}

func setup(monster: MonsterInstance, show_back: bool) -> void:
	_monster = monster
	if not monster or not monster.base_data:
		return

	var data: Resource = monster.base_data
	if show_back and data.get("back_sprite"):
		sprite.texture = data.get("back_sprite")
	elif data.get("front_sprite"):
		sprite.texture = data.get("front_sprite")

	var etype: String = str(data.get("element_type")) if data.get("element_type") else "Normal"
	var ability_str: String = str(data.get("ability")) if data.get("ability") else ""
	if ability_str != "":
		name_label.text = "%s [%s] <%s>" % [str(data.get("monster_name")), etype, ability_str.capitalize()]
	else:
		name_label.text = "%s [%s]" % [str(data.get("monster_name")), etype]
	level_label.text = "Lv.%d" % monster.level
	hp_bar.setup(monster.current_hp, monster.get_max_hp())
	update_status()

func update_hp() -> void:
	if _monster:
		hp_bar.animate_to(_monster.current_hp, _monster.get_max_hp())

func update_status() -> void:
	if not _monster or not status_label:
		return
	if _monster.status == "poison":
		status_label.text = " PSN "
		_apply_status_pill(STATUS_COLORS["poison"])
	elif _monster.status == "burn":
		status_label.text = " BRN "
		_apply_status_pill(STATUS_COLORS["burn"])
	elif _monster.status == "paralysis":
		status_label.text = " PAR "
		_apply_status_pill(STATUS_COLORS["paralysis"])
	else:
		status_label.text = ""
		status_label.remove_theme_stylebox_override("normal")
		status_label.remove_theme_color_override("font_color")

func _apply_status_pill(color: Color) -> void:
	status_label.add_theme_color_override("font_color", Color.WHITE)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(color, 0.8)
	pill.set_corner_radius_all(4)
	pill.set_content_margin_all(2)
	status_label.add_theme_stylebox_override("normal", pill)
