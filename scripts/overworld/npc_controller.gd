extends CharacterBody2D

var dialogue_lines: Array = ["Hello!"]
@export var npc_name: String = "NPC"

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var tex := load("res://assets/sprites/npcs/npc_default.png") as Texture2D
	if tex and sprite:
		sprite.texture = tex

func interact() -> void:
	# Find the dialogue box in the UI layer
	var overworld := get_parent().get_parent()  # NPCs container -> Overworld
	if overworld and overworld.has_method("_show_dialogue"):
		overworld._show_dialogue(dialogue_lines)
	else:
		_show_dialogue_fallback()

func _show_dialogue_fallback() -> void:
	var ui_layer := get_tree().current_scene.find_child("UILayer", true, false)
	if not ui_layer:
		return
	var dialogue_scene := load("res://scenes/overworld/dialogue_box.tscn") as PackedScene
	if dialogue_scene:
		var dialogue := dialogue_scene.instantiate()
		dialogue.set_lines(dialogue_lines)
		ui_layer.add_child(dialogue)

func face_toward(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	# Could flip sprite based on direction
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0
