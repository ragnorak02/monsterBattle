extends Control

@onready var sprite: TextureRect = $VBox/Sprite
@onready var name_label: Label = $VBox/InfoBox/NameLabel
@onready var level_label: Label = $VBox/InfoBox/LevelLabel
@onready var hp_bar: Control = $VBox/InfoBox/HPBar

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

func update_hp() -> void:
	if _monster:
		hp_bar.animate_to(_monster.current_hp, _monster.get_max_hp())
