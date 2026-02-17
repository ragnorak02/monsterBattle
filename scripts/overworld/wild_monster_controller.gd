extends CharacterBody2D

@export var monster_data_id: int = 1
@export var overworld_id: int = 0
@export var level_min: int = 3
@export var level_max: int = 7

var _monster_data: Resource  # MonsterData
var _battle_level: int = 5
var _cooldown_timer: float = 0.0
var _is_on_cooldown: bool = false
var _wander_timer: float = 0.0
var _wander_direction: Vector2 = Vector2.ZERO
var _origin_position: Vector2

const COOLDOWN_DURATION := 5.0
const WANDER_SPEED := 15.0
const WANDER_INTERVAL_MIN := 1.5
const WANDER_INTERVAL_MAX := 4.0
const WANDER_RADIUS := 40.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_origin_position = position
	_battle_level = randi_range(level_min, level_max)
	_monster_data = MonsterDB.get_monster(monster_data_id)
	if _monster_data and _monster_data.get("front_sprite"):
		sprite.texture = _monster_data.get("front_sprite")
		sprite.scale = Vector2(0.5, 0.5)
	_pick_new_wander()

func get_overworld_id() -> int:
	return overworld_id

func _physics_process(delta: float) -> void:
	if _is_on_cooldown:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0:
			_is_on_cooldown = false
			sprite.modulate = Color.WHITE
		return

	# Gentle wandering
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_wander()

	velocity = _wander_direction * WANDER_SPEED
	move_and_slide()

func _pick_new_wander() -> void:
	_wander_timer = randf_range(WANDER_INTERVAL_MIN, WANDER_INTERVAL_MAX)
	# 40% chance to stand still
	if randf() < 0.4:
		_wander_direction = Vector2.ZERO
	else:
		var angle := randf() * TAU
		_wander_direction = Vector2(cos(angle), sin(angle))
	# Drift back toward origin if too far
	var dist := position.distance_to(_origin_position)
	if dist > WANDER_RADIUS:
		_wander_direction = (_origin_position - position).normalized()

func interact() -> void:
	if _is_on_cooldown or GameManager.is_in_battle:
		return
	_start_encounter()

func _start_encounter() -> void:
	# Show encounter UI instead of jumping straight to battle
	var overworld := _get_overworld()
	if overworld and overworld.has_method("show_encounter"):
		overworld.show_encounter(_monster_data, overworld_id, _battle_level)

func on_battle_ended(was_defeated: bool) -> void:
	if was_defeated:
		queue_free()
	else:
		_is_on_cooldown = true
		_cooldown_timer = COOLDOWN_DURATION
		sprite.modulate = Color(1, 1, 1, 0.5)

func _get_overworld() -> Node:
	var parent := get_parent()
	while parent:
		if parent.has_method("show_encounter") or parent.has_method("start_battle"):
			return parent
		parent = parent.get_parent()
	return null
