extends CharacterBody2D

const WALK_SPEED := 80.0
const RUN_SPEED := 140.0
const JUMP_DURATION := 0.3
const ATTACK_DURATION := 0.25
const SWIPE_RANGE := 28.0

var facing_direction := Vector2.DOWN
var _is_moving := false
var _is_running := false
var _is_jumping := false
var _jump_timer := 0.0
var _speed_mode_active := false
var _rt_was_pressed := false
var _is_attacking := false
var _attack_timer := 0.0
var _swipe_area: Area2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	_update_ray_direction()

func _physics_process(delta: float) -> void:
	# 4x speed toggle via RT axis (press-to-toggle, not hold)
	var rt_value := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
	if rt_value > 0.5 and not _rt_was_pressed:
		_rt_was_pressed = true
		_speed_mode_active = not _speed_mode_active
		Engine.time_scale = 4.0 if _speed_mode_active else 1.0
	elif rt_value < 0.3:
		_rt_was_pressed = false
	# Also check keyboard F5 toggle
	if Input.is_action_just_pressed("speed_toggle") and rt_value < 0.3:
		_speed_mode_active = not _speed_mode_active
		Engine.time_scale = 4.0 if _speed_mode_active else 1.0

	# Process swipe attack timer
	if _is_attacking:
		_attack_timer += delta
		if _attack_timer >= ATTACK_DURATION:
			_end_swipe()

	if not GameManager.can_player_move():
		velocity = Vector2.ZERO
		_set_idle_animation()
		return

	# Run toggle
	_is_running = Input.is_action_pressed("run")
	var current_speed: float = RUN_SPEED if _is_running else WALK_SPEED

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")

	if input != Vector2.ZERO:
		input = input.normalized()
		velocity = input * current_speed
		facing_direction = _get_facing_from_input(input)
		_update_ray_direction()
		_set_walk_animation()
		_is_moving = true
	else:
		velocity = Vector2.ZERO
		if _is_moving:
			_set_idle_animation()
			_is_moving = false

	# Animation speed for running
	if animation_player:
		animation_player.speed_scale = 1.8 if _is_running and _is_moving else 1.0

	# Jump arc processing
	if _is_jumping:
		_jump_timer += delta
		var arc := sin(_jump_timer / JUMP_DURATION * PI) * 12.0
		if sprite:
			sprite.offset.y = -8.0 - arc
			# Shadow squash at peak
			var peak_factor := sin(_jump_timer / JUMP_DURATION * PI)
			sprite.scale.y = 1.0 - peak_factor * 0.1
		if _jump_timer >= JUMP_DURATION:
			_is_jumping = false
			_jump_timer = 0.0
			if sprite:
				sprite.offset.y = -8.0
				sprite.scale.y = 1.0

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.can_player_move():
		return

	# Attack (X/F) — swipe or order follower
	if event.is_action_pressed("action") and not _is_attacking and not _is_jumping:
		if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.5:
			_order_follower_action()
		else:
			_start_swipe()
		get_viewport().set_input_as_handled()
		return

	# Jump (Y/Space) — only when moving and not near an interactable
	if event.is_action_pressed("jump") and _is_moving and not _is_jumping:
		if not (interaction_ray and interaction_ray.is_colliding()):
			_is_jumping = true
			_jump_timer = 0.0
			get_viewport().set_input_as_handled()
			return

	# Confirm / A button - interact
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("ui_accept"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	# Menu / Start button - party menu
	if event.is_action_pressed("ui_menu"):
		_open_party_menu()
		get_viewport().set_input_as_handled()
		return

	# I key - inventory
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		_open_inventory()
		get_viewport().set_input_as_handled()
		return

	# P key - pokedex
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		_open_pokedex()
		get_viewport().set_input_as_handled()
		return

	# Q key - quest log
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		_open_quest_log()
		get_viewport().set_input_as_handled()
		return

	# M key - world map
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_open_world_map()
		get_viewport().set_input_as_handled()
		return

func _exit_tree() -> void:
	# Safety net: always restore time scale when leaving overworld
	if _speed_mode_active:
		Engine.time_scale = 1.0
		_speed_mode_active = false
	# Clean up swipe area if active
	if _swipe_area and is_instance_valid(_swipe_area):
		_swipe_area.queue_free()
		_swipe_area = null
		_is_attacking = false

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

func _open_inventory() -> void:
	if GameManager.is_in_menu:
		return
	var inv_scene := load("res://scenes/ui/inventory_ui.tscn") as PackedScene
	if inv_scene:
		var inv := inv_scene.instantiate()
		get_tree().current_scene.add_child(inv)

func _open_pokedex() -> void:
	if GameManager.is_in_menu:
		return
	var dex_scene := load("res://scenes/ui/pokedex.tscn") as PackedScene
	if dex_scene:
		var dex := dex_scene.instantiate()
		get_tree().current_scene.add_child(dex)

func _open_quest_log() -> void:
	if GameManager.is_in_menu:
		return
	var quest_scene := load("res://scenes/ui/quest_log.tscn") as PackedScene
	if quest_scene:
		var quest := quest_scene.instantiate()
		get_tree().current_scene.add_child(quest)

func _open_world_map() -> void:
	if GameManager.is_in_menu:
		return
	var map_scene := load("res://scenes/ui/world_map.tscn") as PackedScene
	if map_scene:
		var map_ui := map_scene.instantiate()
		get_tree().current_scene.add_child(map_ui)

# ── Swipe Attack ──

func _start_swipe() -> void:
	_is_attacking = true
	_attack_timer = 0.0

	# Create Area2D hitbox with semicircle shape in facing direction
	_swipe_area = Area2D.new()
	_swipe_area.collision_layer = 0
	_swipe_area.collision_mask = 12  # layers 4 (NPC) + 8 (wild_monster)
	var shape := CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()

	# Build semicircle points in facing direction
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var base_angle: float = facing_direction.angle()
	var steps := 8
	for i in range(steps + 1):
		var a: float = base_angle - PI / 2.0 + (PI / steps) * i
		points.append(Vector2(cos(a), sin(a)) * SWIPE_RANGE)
	poly.points = points
	shape.shape = poly
	_swipe_area.add_child(shape)
	add_child(_swipe_area)
	_swipe_area.body_entered.connect(_on_swipe_hit)

	# Visual arc (Line2D)
	var arc := Line2D.new()
	arc.width = 2.0
	arc.default_color = Color(1.0, 0.9, 0.5, 0.8)
	for i in range(steps + 1):
		var a: float = base_angle - PI / 2.0 + (PI / steps) * i
		arc.add_point(Vector2(cos(a), sin(a)) * SWIPE_RANGE)
	add_child(arc)
	# Fade out the arc
	var tween := create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, ATTACK_DURATION)
	tween.tween_callback(arc.queue_free)

	# SFX
	AudioManager.play_sfx(AssetRegistry.sfx_hit)

func _on_swipe_hit(body: Node2D) -> void:
	if body.has_method("take_overworld_hit"):
		body.take_overworld_hit()

func _end_swipe() -> void:
	if _swipe_area and is_instance_valid(_swipe_area):
		_swipe_area.queue_free()
		_swipe_area = null
	_is_attacking = false
	_attack_timer = 0.0

# ── Follower Command ──

func _order_follower_action() -> void:
	var follower_node := get_parent().get_node_or_null("Follower")
	if follower_node and follower_node.visible and follower_node.has_method("perform_action"):
		follower_node.perform_action(facing_direction)
