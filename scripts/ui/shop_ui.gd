extends CanvasLayer

@onready var item_list: VBoxContainer = $Panel/MarginContainer/VBox/ItemList
@onready var detail_label: Label = $Panel/MarginContainer/VBox/DetailLabel
@onready var gold_label: Label = $Panel/MarginContainer/VBox/GoldLabel
@onready var hint_bar: PanelContainer = $ControllerHintBar

var _item_buttons: Array[Button] = []

func _ready() -> void:
	GameManager.is_in_menu = true
	_update_gold_display()
	_build_item_list()
	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_a", "label": "Buy"},
			{"icon": "btn_b", "label": "Close"},
			{"icon": "dpad", "label": "Navigate"},
		])

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.get_gold()

func _build_item_list() -> void:
	for btn in _item_buttons:
		btn.queue_free()
	_item_buttons.clear()

	for item_id: String in GameManager.SHOP_PRICES:
		var price: int = GameManager.SHOP_PRICES[item_id]
		var item_def: Dictionary = GameManager.get_item_def(item_id)
		if item_def.is_empty():
			continue
		var btn := Button.new()
		btn.text = "%s — %d gold" % [item_def["name"], price]
		btn.pressed.connect(_on_item_buy.bind(item_id))
		btn.focus_entered.connect(_on_item_focused.bind(item_id))
		item_list.add_child(btn)
		_item_buttons.append(btn)

	if _item_buttons.size() > 0:
		_item_buttons[0].grab_focus()
		var first_id: String = GameManager.SHOP_PRICES.keys()[0]
		_show_item_detail(first_id)

func _on_item_focused(item_id: String) -> void:
	_show_item_detail(item_id)

func _show_item_detail(item_id: String) -> void:
	var item_def: Dictionary = GameManager.get_item_def(item_id)
	if item_def.is_empty():
		return
	var price: int = GameManager.SHOP_PRICES.get(item_id, 0)
	var owned: int = GameManager.get_item_count(item_id)
	var desc: String = ""
	match item_def["type"]:
		"heal":
			desc = "Restores %d HP." % int(item_def["value"])
		"catch":
			desc = "Catch rate x%.1f." % float(item_def["value"])
		"cure":
			desc = "Cures %s." % str(item_def["value"])
		_:
			desc = "An item."
	detail_label.text = "%s — %d gold\n%s\nOwned: %d" % [item_def["name"], price, desc, owned]

func _on_item_buy(item_id: String) -> void:
	var price: int = GameManager.SHOP_PRICES.get(item_id, 0)
	var item_def: Dictionary = GameManager.get_item_def(item_id)
	if item_def.is_empty():
		return
	if GameManager.spend_gold(price):
		GameManager.add_item(item_id)
		detail_label.text = "Bought %s!" % item_def["name"]
		_update_gold_display()
		_build_item_list()
	else:
		detail_label.text = "Not enough gold!"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
