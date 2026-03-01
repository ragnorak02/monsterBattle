extends StaticBody2D

var target_area: String = ""
var is_exit: bool = false
var return_area: String = ""
var return_position: Vector2 = Vector2.ZERO
var building_name: String = ""

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_near)
		interaction_zone.body_exited.connect(_on_player_away)
	if prompt_label:
		prompt_label.visible = false

func interact() -> void:
	var overworld := _get_overworld()
	if not overworld:
		return
	if is_exit:
		# Exiting building — restore outdoor state
		GameManager.is_in_building = false
		GameManager.current_area = GameManager.building_return_area
		GameManager.set_area_player_position(GameManager.building_return_area, GameManager.building_return_position)
		GameManager.building_return_area = ""
		GameManager.building_return_position = Vector2.ZERO
	else:
		# Entering building — save return info
		GameManager.is_in_building = true
		GameManager.building_return_area = GameManager.current_area
		GameManager.building_return_position = overworld.player.position
		GameManager.current_area = target_area
	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")

func _get_overworld() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("_show_dialogue"):
			return node
		node = node.get_parent()
	return null

func _on_player_near(body: Node2D) -> void:
	if body.is_in_group("player"):
		if prompt_label:
			prompt_label.visible = true

func _on_player_away(body: Node2D) -> void:
	if body.is_in_group("player"):
		if prompt_label:
			prompt_label.visible = false
