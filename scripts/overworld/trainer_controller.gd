extends CharacterBody2D

var dialogue_before: Array = ["Let's battle!"]
var dialogue_after: Array = ["You win..."]
@export var trainer_id: String = ""
@export var trainer_name: String = "Trainer"
@export var bubble_text: String = "..."
@export var sight_range: float = 80.0
@export var sight_direction: Vector2 = Vector2.DOWN
var monster_ids: Array = []
var monster_levels: Array = []
var is_gym_leader: bool = false
var badge_id: String = ""

var _is_engaging: bool = false
var _exclamation_label: Label = null

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

func _physics_process(_delta: float) -> void:
	if _is_engaging:
		return
	if GameManager.is_trainer_defeated(trainer_id):
		return
	if GameManager.is_in_battle or GameManager.is_in_dialogue or GameManager.is_in_menu:
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_node: Node2D = players[0]

	var to_player := player_node.global_position - global_position
	var dist := to_player.length()
	if dist > sight_range or dist < 1.0:
		return

	var dir_normalized := to_player.normalized()
	var sight_normalized := sight_direction.normalized()
	var dot := dir_normalized.dot(sight_normalized)
	# ~45-degree cone: cos(45) ≈ 0.707
	if dot < 0.707:
		return

	# Player is in sight cone — auto-engage!
	_start_engage(player_node)

func interact() -> void:
	if GameManager.is_trainer_defeated(trainer_id):
		_show_dialogue(dialogue_after)
	else:
		_show_dialogue_then_battle()

func _start_engage(player_node: Node2D) -> void:
	_is_engaging = true
	if GameManager.DEBUG_TRAINER:
		print("[TRAINER] %s: engaging player at %s" % [trainer_id, str(player_node.global_position)])
	face_toward(player_node.global_position)

	# Show "!" exclamation
	_exclamation_label = Label.new()
	_exclamation_label.text = "!"
	_exclamation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exclamation_label.add_theme_font_size_override("font_size", 12)
	_exclamation_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	_exclamation_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
	_exclamation_label.add_theme_constant_override("outline_size", 4)
	_exclamation_label.position = Vector2(-6, -28)
	add_child(_exclamation_label)

	# Freeze player
	GameManager.is_in_dialogue = true

	# Brief tween walk toward player (16px), then await completion
	var walk_dir := (player_node.global_position - global_position).normalized()
	var tween := create_tween()
	tween.tween_property(self, "position", position + walk_dir * 16.0, 0.3)
	await tween.finished
	await get_tree().create_timer(0.3).timeout

	if GameManager.DEBUG_TRAINER:
		print("[TRAINER] %s: engage walk complete, starting battle sequence" % trainer_id)

	# Remove exclamation
	if _exclamation_label:
		_exclamation_label.queue_free()
		_exclamation_label = null

	# Show dialogue then start battle
	_show_dialogue_then_battle()

func _get_overworld() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("_show_dialogue"):
			return node
		node = node.get_parent()
	return null

func _show_dialogue_then_battle() -> void:
	var overworld := _get_overworld()
	if GameManager.DEBUG_TRAINER:
		print("[TRAINER] %s: _show_dialogue_then_battle called, overworld=%s" % [trainer_id, str(overworld)])
	if overworld:
		var dialogue_node: Node = overworld._show_dialogue(dialogue_before)
		if dialogue_node:
			dialogue_node.block_cancel = true
			await dialogue_node.dialogue_closed
		await get_tree().create_timer(0.3).timeout
		if overworld.has_method("start_trainer_battle"):
			overworld.start_trainer_battle(self)
	else:
		if GameManager.DEBUG_TRAINER:
			print("[TRAINER] %s: ERROR — could not find overworld with _show_dialogue" % trainer_id)

func _show_dialogue(lines: Array) -> void:
	var overworld := _get_overworld()
	if overworld:
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
	_is_engaging = false
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
