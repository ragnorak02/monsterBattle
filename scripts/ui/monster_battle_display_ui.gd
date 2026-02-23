extends Control

@onready var sprite: TextureRect = $VBox/Sprite
@onready var name_label: Label = $VBox/InfoBox/NameLabel
@onready var level_label: Label = $VBox/InfoBox/LevelLabel
@onready var hp_bar: Control = $VBox/InfoBox/HPBar
@onready var status_label: Label = $VBox/InfoBox/StatusLabel

var _monster: MonsterInstance

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
		status_label.text = "PSN"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.9))  # purple
	elif _monster.status == "burn":
		status_label.text = "BRN"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))  # orange-red
	elif _monster.status == "paralysis":
		status_label.text = "PAR"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # yellow
	else:
		status_label.text = ""
