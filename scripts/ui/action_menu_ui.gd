extends PanelContainer

signal skill_selected(skill: Resource)
signal run_selected

@onready var skill_container: VBoxContainer = $MarginContainer/VBox/SkillContainer
@onready var run_button: Button = $MarginContainer/VBox/RunButton

var _skill_buttons: Array[Button] = []

func _ready() -> void:
	run_button.pressed.connect(func(): run_selected.emit())

func setup_skills(skills: Array) -> void:
	# Clear existing buttons
	for btn in _skill_buttons:
		btn.queue_free()
	_skill_buttons.clear()

	for skill in skills:
		var btn := Button.new()
		btn.text = "%s (Pow: %d)" % [str(skill.get("skill_name")), int(skill.get("power"))]
		btn.pressed.connect(func(): skill_selected.emit(skill))
		skill_container.add_child(btn)
		_skill_buttons.append(btn)

	# Focus first skill button
	if _skill_buttons.size() > 0:
		_skill_buttons[0].call_deferred("grab_focus")

func set_enabled(enabled: bool) -> void:
	for btn in _skill_buttons:
		btn.disabled = not enabled
	run_button.disabled = not enabled
