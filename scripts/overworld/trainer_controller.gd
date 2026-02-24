extends CharacterBody2D

var dialogue_before: Array = ["Let's battle!"]
var dialogue_after: Array = ["You win..."]
@export var trainer_id: String = ""
@export var trainer_name: String = "Trainer"
@export var bubble_text: String = "..."
var monster_ids: Array = []
var monster_levels: Array = []
var is_gym_leader: bool = false
var badge_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var chat_bubble: Label = $ChatBubble
@onready var interaction_zone: Area2D = $InteractionZone

func _ready() -> void:
	var tex := AssetRegistry.load_texture(AssetRegistry.npc_default_sprite)
	if tex and sprite:
		sprite.texture = tex
		sprite.hframes = 3
	if chat_bubble:
		chat_bubble.text = trainer_name
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_near)
		interaction_zone.body_exited.connect(_on_player_away)

func interact() -> void:
	if GameManager.is_trainer_defeated(trainer_id):
		_show_dialogue(dialogue_after)
	else:
		_show_dialogue_then_battle()

func _show_dialogue_then_battle() -> void:
	var overworld := get_parent().get_parent()  # NPCs container -> Overworld
	if overworld and overworld.has_method("_show_dialogue"):
		overworld._show_dialogue(dialogue_before)
		# Wait for dialogue to close, then start battle
		await get_tree().create_timer(0.5 + dialogue_before.size() * 1.5).timeout
		if overworld.has_method("start_trainer_battle"):
			overworld.start_trainer_battle(self)

func _show_dialogue(lines: Array) -> void:
	var overworld := get_parent().get_parent()
	if overworld and overworld.has_method("_show_dialogue"):
		overworld._show_dialogue(lines)

func get_party() -> Array:
	var party: Array = []
	for i in monster_ids.size():
		var data: Resource = MonsterDB.get_monster(monster_ids[i])
		if data:
			var level: int = monster_levels[i] if i < monster_levels.size() else 5
			party.append({"data": data, "level": level})
	return party

func on_defeated() -> void:
	if chat_bubble:
		chat_bubble.text = "..."

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
