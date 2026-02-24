extends Node2D

## Follower monster that trails behind the player in the overworld.
## 3-state machine: FOLLOWING → IDLE → ROAMING.
## Displays party[0]'s front_sprite scaled down.

enum State { FOLLOWING, IDLE, ROAMING }

# ── Constants ──
const TRAIL_LENGTH := 10
const FOLLOW_DISTANCE := 20.0
const FOLLOW_SPEED := 85.0
const IDLE_THRESHOLD := 2.0
const ROAM_THRESHOLD := 3.0
const ROAM_RADIUS := 12.0
const ROAM_SPEED := 15.0
const BOB_AMPLITUDE := 2.0
const BOB_SPEED := 8.0
const BREATHE_AMPLITUDE := 0.02
const BREATHE_SPEED := 3.0
const SPRITE_SCALE := Vector2(0.5, 0.5)
const BEHIND_CHECK_DOT := 0.0
const FRONT_CONE_DIST := 24.0

# ── State ──
var _state: State = State.FOLLOWING
var _target_node: CharacterBody2D
var _position_history: Array[Vector2] = []
var _idle_timer: float = 0.0
var _roam_angle: float = 0.0
var _roam_origin: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _last_player_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func setup(player_node: CharacterBody2D) -> void:
	_target_node = player_node
	_update_sprite()
	snap_to_player()
	GameManager.party_changed.connect(_on_party_changed)

func snap_to_player() -> void:
	if not _target_node:
		return
	_position_history.clear()
	var facing: Vector2 = _get_player_facing()
	global_position = _target_node.global_position - facing * FOLLOW_DISTANCE
	for i in TRAIL_LENGTH:
		_position_history.append(_target_node.global_position)
	_state = State.FOLLOWING
	_idle_timer = 0.0

func _physics_process(delta: float) -> void:
	if not _target_node or not visible:
		return

	_time += delta
	var player_pos: Vector2 = _target_node.global_position

	match _state:
		State.FOLLOWING:
			_process_following(delta, player_pos)
		State.IDLE:
			_process_idle(delta, player_pos)
		State.ROAMING:
			_process_roaming(delta, player_pos)

	_last_player_pos = player_pos

func _process_following(delta: float, player_pos: Vector2) -> void:
	# Record trail positions when player moves
	if _position_history.is_empty() or player_pos.distance_to(_position_history[-1]) > 1.0:
		_position_history.append(player_pos)
		_idle_timer = 0.0

	# Trim trail
	while _position_history.size() > TRAIL_LENGTH:
		_position_history.pop_front()

	# Find best "behind" position from trail
	var target_pos: Vector2 = _get_behind_position(player_pos)

	# Smooth lerp toward target
	var dist: float = global_position.distance_to(target_pos)
	if dist > 1.0:
		global_position = global_position.lerp(target_pos, minf(FOLLOW_SPEED * delta / dist, 1.0))

	# Safety: if follower is in front of player, push it behind
	_enforce_behind(delta, player_pos)

	# Walking bob animation
	sprite.offset.y = sin(_time * BOB_SPEED) * BOB_AMPLITUDE
	sprite.scale = SPRITE_SCALE

	# Check if player stopped moving → transition to IDLE
	var player_moved: bool = player_pos.distance_to(_last_player_pos) > 0.5
	if not player_moved:
		_idle_timer += delta
		if _idle_timer >= IDLE_THRESHOLD:
			_state = State.IDLE
			_idle_timer = 0.0
			sprite.offset.y = 0.0
	else:
		_idle_timer = 0.0

func _process_idle(delta: float, player_pos: Vector2) -> void:
	# Breathe animation (subtle scale pulse)
	var breathe: float = 1.0 + sin(_time * BREATHE_SPEED) * BREATHE_AMPLITUDE
	sprite.scale = SPRITE_SCALE * breathe
	sprite.offset.y = 0.0

	_idle_timer += delta

	# If player starts moving again → back to FOLLOWING
	var player_moved: bool = player_pos.distance_to(_last_player_pos) > 0.5
	if player_moved:
		_state = State.FOLLOWING
		_idle_timer = 0.0
		return

	# After additional time, start ROAMING
	if _idle_timer >= (ROAM_THRESHOLD - IDLE_THRESHOLD):
		_state = State.ROAMING
		_roam_origin = global_position
		_roam_angle = randf() * TAU
		_idle_timer = 0.0

func _process_roaming(delta: float, player_pos: Vector2) -> void:
	# If player starts moving → snap back to FOLLOWING
	var player_moved: bool = player_pos.distance_to(_last_player_pos) > 0.5
	if player_moved:
		_state = State.FOLLOWING
		_idle_timer = 0.0
		sprite.offset.y = 0.0
		sprite.scale = SPRITE_SCALE
		return

	# Wander in small semicircle behind player
	_roam_angle += ROAM_SPEED * delta * 0.1
	var facing: Vector2 = _get_player_facing()
	var behind_center: Vector2 = player_pos - facing * FOLLOW_DISTANCE

	# Constrain roam to behind-player semicircle
	var roam_offset := Vector2(cos(_roam_angle), sin(_roam_angle)) * ROAM_RADIUS
	var roam_target: Vector2 = behind_center + roam_offset

	global_position = global_position.lerp(roam_target, ROAM_SPEED * delta / maxf(global_position.distance_to(roam_target), 1.0))

	# Gentle bob while roaming
	sprite.offset.y = sin(_time * BOB_SPEED * 0.5) * BOB_AMPLITUDE * 0.5
	var breathe: float = 1.0 + sin(_time * BREATHE_SPEED) * BREATHE_AMPLITUDE
	sprite.scale = SPRITE_SCALE * breathe

# ── Behind-Player Logic ──

func _get_player_facing() -> Vector2:
	if _target_node and "facing_direction" in _target_node:
		var fd: Vector2 = _target_node.facing_direction
		if fd != Vector2.ZERO:
			return fd.normalized()
	return Vector2.DOWN

func _get_behind_position(player_pos: Vector2) -> Vector2:
	var facing: Vector2 = _get_player_facing()

	# Filter trail: prefer positions that are behind the player
	var best_pos: Vector2 = player_pos - facing * FOLLOW_DISTANCE
	var best_score: float = -1.0

	for pos in _position_history:
		var to_pos: Vector2 = pos - player_pos
		var dot_val: float = to_pos.dot(facing)
		var dist: float = pos.distance_to(player_pos)

		# Behind = negative dot product with facing
		if dot_val < BEHIND_CHECK_DOT and dist >= FOLLOW_DISTANCE * 0.5:
			var score: float = -dot_val + (1.0 / maxf(abs(dist - FOLLOW_DISTANCE), 1.0))
			if score > best_score:
				best_score = score
				best_pos = pos
	return best_pos

func _enforce_behind(delta: float, player_pos: Vector2) -> void:
	var facing: Vector2 = _get_player_facing()
	var to_follower: Vector2 = global_position - player_pos
	var dot_val: float = to_follower.dot(facing)

	# If follower is in front of player (positive dot) and close
	if dot_val > 0.0 and to_follower.length() < FRONT_CONE_DIST:
		var behind_pos: Vector2 = player_pos - facing * FOLLOW_DISTANCE
		global_position = global_position.lerp(behind_pos, 4.0 * delta)

# ── Sprite Management ──

func _update_sprite() -> void:
	if GameManager.player_party.is_empty():
		visible = false
		return

	visible = true
	var lead: MonsterInstance = GameManager.player_party[0]
	if lead and lead.base_data:
		var tex: Texture2D = lead.base_data.get("front_sprite") as Texture2D
		if tex:
			sprite.texture = tex
			sprite.scale = SPRITE_SCALE
		else:
			visible = false
	else:
		visible = false

func _on_party_changed() -> void:
	_update_sprite()
