extends Control

var _starters: Array = []
var _cards: Array[PanelContainer] = []

func _ready() -> void:
	_starters = MonsterDB.get_starter_monsters()
	print("StarterSelect: Got %d starters" % _starters.size())
	for s in _starters:
		if s:
			print("  Starter: %s, front_sprite: %s" % [str(s.get("monster_name")), str(s.get("front_sprite"))])
		else:
			print("  Starter: null!")
	_cards = [
		$VBox/CardContainer/Card1,
		$VBox/CardContainer/Card2,
		$VBox/CardContainer/Card3
	]

	for i in _starters.size():
		_setup_card(i, _starters[i])

	# Focus first button
	var first_btn := _cards[0].get_node("VBox/SelectButton") as Button
	if first_btn:
		first_btn.grab_focus()

func _setup_card(index: int, monster_data: Resource) -> void:
	if not monster_data:
		return
	var card := _cards[index]
	var sprite := card.get_node("VBox/Sprite") as TextureRect
	var name_label := card.get_node("VBox/Name") as Label
	var stats_label := card.get_node("VBox/Stats") as Label
	var button := card.get_node("VBox/SelectButton") as Button

	var front_tex = monster_data.get("front_sprite")
	if front_tex:
		sprite.texture = front_tex
	name_label.text = str(monster_data.get("monster_name"))
	stats_label.text = "HP:%d ATK:%d\nDEF:%d AGI:%d" % [
		int(monster_data.get("max_hp")), int(monster_data.get("attack")),
		int(monster_data.get("defense")), int(monster_data.get("agility"))
	]
	button.pressed.connect(_on_starter_selected.bind(index))

func _on_starter_selected(index: int) -> void:
	var data: Resource = _starters[index]
	var instance := MonsterInstance.new(data, 5)
	GameManager.add_to_party(instance)
	GameManager.add_item("potion", 5)
	GameManager.add_item("capture_ball", 10)
	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")
