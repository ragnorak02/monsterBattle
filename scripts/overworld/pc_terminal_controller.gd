extends CharacterBody2D

@export var bubble_text: String = "PC Terminal"

@onready var sprite: Sprite2D = $Sprite2D
@onready var chat_bubble: Label = $ChatBubble
@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	var tex := load("res://assets/sprites/npcs/npc_default.png") as Texture2D
	if tex and sprite:
		sprite.texture = tex
		sprite.hframes = 3
		sprite.modulate = Color(0.6, 0.8, 1.0)
	if chat_bubble:
		chat_bubble.text = bubble_text
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_near)
		interaction_zone.body_exited.connect(_on_player_away)

func interact() -> void:
	if GameManager.is_in_menu:
		return
	var pc_scene := load("res://scenes/ui/pc_storage.tscn") as PackedScene
	if pc_scene:
		var ui_layer := get_tree().current_scene.find_child("UILayer", true, false)
		if ui_layer:
			ui_layer.add_child(pc_scene.instantiate())

func _on_player_near(body: Node2D) -> void:
	if body.is_in_group("player"):
		if chat_bubble:
			chat_bubble.visible = true

func _on_player_away(body: Node2D) -> void:
	if body.is_in_group("player"):
		if chat_bubble:
			chat_bubble.visible = false
