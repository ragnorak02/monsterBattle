extends PanelContainer

signal skill_selected(skill: Resource)
signal catch_selected
signal run_selected
signal item_selected(item_id: String)
signal replace_skill_chosen(index: int)

@onready var skill_container: VBoxContainer = $MarginContainer/VBox/SkillContainer
@onready var catch_button: Button = $MarginContainer/VBox/CatchButton
@onready var run_button: Button = $MarginContainer/VBox/RunButton

var _skill_buttons: Array[Button] = []
var _item_buttons: Array[Button] = []
var _items_button: Button = null
var _in_replace_mode: bool = false
var _in_items_mode: bool = false

func _ready() -> void:
	catch_button.pressed.connect(func(): catch_selected.emit())
	run_button.pressed.connect(func(): run_selected.emit())

func setup_skills(skills: Array) -> void:
	_in_replace_mode = false
	_close_items_submenu()
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()

	for skill in skills:
		var btn := Button.new()
		var stype: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
		btn.text = "%s [%s] (Pow: %d)" % [str(skill.get("skill_name")), stype, int(skill.get("power"))]
		btn.pressed.connect(func(): skill_selected.emit(skill))
		skill_container.add_child(btn)
		_skill_buttons.append(btn)

	# Add Items button if not already present
	if _items_button:
		_items_button.queue_free()
		_items_button = null
	_items_button = Button.new()
	_items_button.text = "Items"
	_items_button.pressed.connect(_on_items_pressed)
	skill_container.add_child(_items_button)

	if _skill_buttons.size() > 0:
		_skill_buttons[0].call_deferred("grab_focus")

func set_enabled(enabled: bool) -> void:
	for btn in _skill_buttons:
		btn.disabled = not enabled
	for btn in _item_buttons:
		btn.disabled = not enabled
	catch_button.disabled = not enabled
	run_button.disabled = not enabled
	if _items_button:
		_items_button.disabled = not enabled

func set_catch_visible(flag: bool) -> void:
	catch_button.visible = flag

func _on_items_pressed() -> void:
	if _in_items_mode:
		_close_items_submenu()
		return
	_show_items_submenu()

func _show_items_submenu() -> void:
	_in_items_mode = true
	# Hide skill buttons and other action buttons
	for btn in _skill_buttons:
		btn.visible = false
	catch_button.visible = false
	run_button.visible = false
	if _items_button:
		_items_button.visible = false

	var battle_items: Array = GameManager.get_battle_items()
	if battle_items.is_empty():
		var empty_label := Button.new()
		empty_label.text = "No items!"
		empty_label.disabled = true
		skill_container.add_child(empty_label)
		_item_buttons.append(empty_label)
	else:
		for item in battle_items:
			var btn := Button.new()
			var iid: String = item["id"]
			btn.text = "%s x%d" % [item["name"], item["count"]]
			btn.pressed.connect(func(): _on_item_picked(iid))
			skill_container.add_child(btn)
			_item_buttons.append(btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_close_items_submenu)
	skill_container.add_child(back_btn)
	_item_buttons.append(back_btn)

	if _item_buttons.size() > 0:
		_item_buttons[0].call_deferred("grab_focus")

func _close_items_submenu() -> void:
	_in_items_mode = false
	for btn in _item_buttons:
		btn.queue_free()
	_item_buttons.clear()
	# Restore skill buttons
	for btn in _skill_buttons:
		btn.visible = true
	catch_button.visible = true
	run_button.visible = true
	if _items_button:
		_items_button.visible = true
	if _skill_buttons.size() > 0:
		_skill_buttons[0].call_deferred("grab_focus")

func _on_item_picked(item_id: String) -> void:
	_close_items_submenu()
	item_selected.emit(item_id)

func setup_skill_replace(current_skills: Array, new_skill: Resource) -> void:
	_in_replace_mode = true
	_close_items_submenu()
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()
	if _items_button:
		_items_button.queue_free()
		_items_button = null

	catch_button.visible = false
	run_button.visible = false

	var new_name: String = str(new_skill.get("skill_name"))
	var new_pow: int = int(new_skill.get("power"))

	for i in current_skills.size():
		var skill: Resource = current_skills[i]
		var btn := Button.new()
		btn.text = "Forget: %s (Pow:%d)" % [str(skill.get("skill_name")), int(skill.get("power"))]
		var idx := i
		btn.pressed.connect(func(): _on_replace_picked(idx))
		skill_container.add_child(btn)
		_skill_buttons.append(btn)

	var skip_btn := Button.new()
	skip_btn.text = "Don't learn %s" % new_name
	skip_btn.pressed.connect(func(): _on_replace_picked(-1))
	skill_container.add_child(skip_btn)
	_skill_buttons.append(skip_btn)

	if _skill_buttons.size() > 0:
		_skill_buttons[0].call_deferred("grab_focus")

	set_enabled(true)

func _on_replace_picked(index: int) -> void:
	_in_replace_mode = false
	catch_button.visible = true
	run_button.visible = true
	replace_skill_chosen.emit(index)
