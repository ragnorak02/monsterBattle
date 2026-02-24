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
var _trainer_mode: bool = false

func _ready() -> void:
	catch_button.pressed.connect(func(): catch_selected.emit())
	run_button.pressed.connect(func(): run_selected.emit())
	catch_button.add_theme_font_size_override("font_size", 8)
	run_button.add_theme_font_size_override("font_size", 8)

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

func setup_skills(skills: Array) -> void:
	_in_replace_mode = false
	_close_items_submenu()
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()

	for skill in skills:
		var btn := Button.new()
		var stype: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
		var category: String = str(skill.get("category")) if skill.get("category") else "physical"
		var cat_tag: String = "[P]" if category == "physical" else "[S]"
		btn.text = "%s %s Pow:%d" % [cat_tag, str(skill.get("skill_name")), int(skill.get("power"))]
		btn.add_theme_font_size_override("font_size", 8)
		# Type color tint
		if TYPE_COLORS.has(stype):
			var style := StyleBoxFlat.new()
			style.bg_color = Color(TYPE_COLORS[stype], 0.25)
			style.set_border_width_all(1)
			style.border_color = Color(TYPE_COLORS[stype], 0.5)
			style.set_corner_radius_all(3)
			style.set_content_margin_all(2)
			btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(func(): skill_selected.emit(skill))
		skill_container.add_child(btn)
		_skill_buttons.append(btn)

	# Add Items button if not already present
	if _items_button:
		_items_button.queue_free()
		_items_button = null
	_items_button = Button.new()
	_items_button.text = "Items"
	_items_button.add_theme_font_size_override("font_size", 8)
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

func set_trainer_mode(enabled: bool) -> void:
	_trainer_mode = enabled
	catch_button.visible = not enabled
	run_button.visible = not enabled
	if _items_button:
		_items_button.visible = not enabled

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
		empty_label.add_theme_font_size_override("font_size", 8)
		skill_container.add_child(empty_label)
		_item_buttons.append(empty_label)
	else:
		for item in battle_items:
			var btn := Button.new()
			var iid: String = item["id"]
			btn.text = "%s x%d" % [item["name"], item["count"]]
			btn.add_theme_font_size_override("font_size", 8)
			btn.pressed.connect(func(): _on_item_picked(iid))
			skill_container.add_child(btn)
			_item_buttons.append(btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.add_theme_font_size_override("font_size", 8)
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
	if not _trainer_mode:
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
