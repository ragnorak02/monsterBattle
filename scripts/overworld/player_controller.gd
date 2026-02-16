extends CharacterBody2D

const SPEED := 80.0

var facing_direction := Vector2.DOWN
var _is_moving := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	_update_ray_direction()

func _physics_process(_delta: float) -> void:
	if not GameManager.can_player_move():
		velocity = Vector2.ZERO
		_set_idle_animation()
		return

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")

	if input != Vector2.ZERO:
		input = input.normalized()
		velocity = input * SPEED
		facing_direction = _get_facing_from_input(input)
		_update_ray_direction()
		_set_walk_animation()
		_is_moving = true
	else:
		velocity = Vector2.ZERO
		if _is_moving:
			_set_idle_animation()
			_is_moving = false

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.can_player_move():
		return

	# Confirm / A button - interact
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("ui_accept"):
		_try_interact()
		get_viewport().set_input_as_handled()

	# Menu / Start button - party menu
	if event.is_action_pressed("ui_menu"):
		_open_party_menu()
		get_viewport().set_input_as_handled()

func _get_facing_from_input(input: Vector2) -> Vector2:
	if abs(input.x) > abs(input.y):
		return Vector2(sign(input.x), 0)
	else:
		return Vector2(0, sign(input.y))

func _update_ray_direction() -> void:
	if interaction_ray:
		interaction_ray.target_position = facing_direction * 24

func _set_walk_animation() -> void:
	if not animation_player:
		return
	var dir_name := _direction_name()
	var anim_name := "walk_" + dir_name
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _set_idle_animation() -> void:
	if not animation_player:
		return
	var dir_name := _direction_name()
	var anim_name := "idle_" + dir_name
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _direction_name() -> String:
	if facing_direction == Vector2.UP:
		return "up"
	elif facing_direction == Vector2.DOWN:
		return "down"
	elif facing_direction == Vector2.LEFT:
		return "left"
	else:
		return "right"

func _try_interact() -> void:
	if interaction_ray and interaction_ray.is_colliding():
		var collider := interaction_ray.get_collider()
		print("Interact ray hit: ", collider.name if collider else "null")
		if collider and collider.has_method("interact"):
			collider.interact()
	else:
		print("Interact: nothing in range (ray enabled=%s)" % str(interaction_ray.enabled if interaction_ray else "no ray"))

func _open_party_menu() -> void:
	if GameManager.is_in_menu:
		return
	var menu_scene := load("res://scenes/ui/party_menu.tscn") as PackedScene
	if menu_scene:
		var menu := menu_scene.instantiate()
		get_tree().current_scene.add_child(menu)
