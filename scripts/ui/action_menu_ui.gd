extends PanelContainer

signal skill_selected(skill: Resource)
signal catch_selected
signal run_selected
signal replace_skill_chosen(index: int)

@onready var skill_container: VBoxContainer = $MarginContainer/VBox/SkillContainer
@onready var catch_button: Button = $MarginContainer/VBox/CatchButton
@onready var run_button: Button = $MarginContainer/VBox/RunButton

var _skill_buttons: Array[Button] = []
var _in_replace_mode: bool = false

func _ready() -> void:
	catch_button.pressed.connect(func(): catch_selected.emit())
	run_button.pressed.connect(func(): run_selected.emit())

func setup_skills(skills: Array) -> void:
	_in_replace_mode = false
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()

	for skill in skills:
		var btn := Button.new()
		btn.text = "%s (Pow: %d)" % [str(skill.get("skill_name")), int(skill.get("power"))]
		btn.pressed.connect(func(): skill_selected.emit(skill))
		skill_container.add_child(btn)
		_skill_buttons.append(btn)

	if _skill_buttons.size() > 0:
		_skill_buttons[0].call_deferred("grab_focus")

func set_enabled(enabled: bool) -> void:
	for btn in _skill_buttons:
		btn.disabled = not enabled
	catch_button.disabled = not enabled
	run_button.disabled = not enabled

func set_catch_visible(flag: bool) -> void:
	catch_button.visible = flag

func setup_skill_replace(current_skills: Array, new_skill: Resource) -> void:
	_in_replace_mode = true
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()

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
