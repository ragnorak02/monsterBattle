extends CanvasLayer

@onready var item_list: VBoxContainer = $Panel/MarginContainer/VBox/ItemList
@onready var detail_label: Label = $Panel/MarginContainer/VBox/DetailLabel

var _item_buttons: Array[Button] = []

func _ready() -> void:
	GameManager.is_in_menu = true
	_build_item_list()

func _build_item_list() -> void:
	for btn in _item_buttons:
		btn.queue_free()
	_item_buttons.clear()

	if GameManager.inventory.is_empty():
		detail_label.text = "No items in inventory."
		return

	for item_id: String in GameManager.inventory:
		var count: int = GameManager.inventory[item_id]
		var item_def: Dictionary = GameManager.get_item_def(item_id)
		if item_def.is_empty():
			continue
		var btn := Button.new()
		btn.text = "%s x%d" % [item_def["name"], count]
		btn.pressed.connect(_on_item_selected.bind(item_id))
		btn.focus_entered.connect(_on_item_focused.bind(item_id))
		item_list.add_child(btn)
		_item_buttons.append(btn)

	if _item_buttons.size() > 0:
		_item_buttons[0].grab_focus()
		_show_item_detail(_item_buttons[0].text.split(" x")[0] if _item_buttons.size() > 0 else "")
		# Show detail for first item
		var first_id: String = GameManager.inventory.keys()[0]
		_show_item_detail_by_id(first_id)

func _on_item_focused(item_id: String) -> void:
	_show_item_detail_by_id(item_id)

func _on_item_selected(item_id: String) -> void:
	var item_def: Dictionary = GameManager.get_item_def(item_id)
	if item_def.is_empty():
		return

	var item_type: String = item_def["type"]
	if item_type == "heal":
		_use_heal_item(item_id, item_def)
	else:
		detail_label.text = "%s can only be used in battle." % item_def["name"]

func _use_heal_item(item_id: String, item_def: Dictionary) -> void:
	var heal_amount: int = int(item_def["value"])
	# Find first hurt monster
	var target: MonsterInstance = null
	for monster in GameManager.player_party:
		if not monster.is_fainted() and monster.current_hp < monster.get_max_hp():
			target = monster
			break

	if not target:
		detail_label.text = "No one needs healing!"
		return

	if not GameManager.remove_item(item_id):
		return

	var name_str: String = str(target.base_data.get("monster_name"))
	var old_hp: int = target.current_hp
	target.heal(heal_amount)
	var healed: int = target.current_hp - old_hp
	detail_label.text = "%s healed %s for %d HP!" % [item_def["name"], name_str, healed]
	_build_item_list()

func _show_item_detail_by_id(item_id: String) -> void:
	var item_def: Dictionary = GameManager.get_item_def(item_id)
	if item_def.is_empty():
		return
	var count: int = GameManager.get_item_count(item_id)
	var desc: String = ""
	match item_def["type"]:
		"heal":
			desc = "Restores %d HP." % int(item_def["value"])
		"catch":
			desc = "Catch rate x%.1f." % float(item_def["value"])
		_:
			desc = "An item."
	detail_label.text = "%s (x%d)\n%s" % [item_def["name"], count, desc]

func _show_item_detail(_text: String) -> void:
	pass  # Handled by _show_item_detail_by_id

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
