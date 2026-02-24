extends CharacterBody2D

var dialogue_lines: Array = ["Hello!"]
var dialogue_tree: Array = []
@export var npc_name: String = "NPC"
@export var bubble_text: String = "Hello!"

@onready var sprite: Sprite2D = $Sprite2D
@onready var chat_bubble: Label = $ChatBubble
@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	var tex := AssetRegistry.load_texture(AssetRegistry.npc_default_sprite)
	if tex and sprite:
		sprite.texture = tex
		sprite.hframes = 3
	if chat_bubble:
		chat_bubble.text = bubble_text
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_near)
		interaction_zone.body_exited.connect(_on_player_away)

func interact() -> void:
	var overworld := get_parent().get_parent()  # NPCs container -> Overworld
	if dialogue_tree.size() > 0 and overworld and overworld.has_method("_show_dialogue_tree"):
		overworld._show_dialogue_tree(dialogue_tree)
	elif overworld and overworld.has_method("_show_dialogue"):
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
	if sprite and dir.x != 0:
		sprite.flip_h = dir.x < 0

func _on_player_near(body: Node2D) -> void:
	if body.is_in_group("player"):
		if chat_bubble:
			chat_bubble.visible = true
		face_toward(body.global_position)

func _on_player_away(body: Node2D) -> void:
	if body.is_in_group("player"):
		if chat_bubble:
			chat_bubble.visible = false
