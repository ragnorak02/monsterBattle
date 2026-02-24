extends Node2D

var _weather_type: String = "clear"
var _ui_layer: CanvasLayer = null
var _particles: CPUParticles2D = null
var _overlay: ColorRect = null

func setup(p_ui_layer: CanvasLayer) -> void:
	_ui_layer = p_ui_layer

func get_weather() -> String:
	return _weather_type

func set_weather(weather_type: String) -> void:
	_clear_effects()
	_weather_type = weather_type
	match weather_type:
		"rain":
			_create_particles(100, Vector2(0, 300), Vector2(20, 20), Color(0.6, 0.7, 1.0, 0.6))
			_create_overlay(Color(0.4, 0.5, 0.7, 0.15))
		"snow":
			_create_particles(60, Vector2(0, 80), Vector2(40, 40), Color(1.0, 1.0, 1.0, 0.8))
			_create_overlay(Color(0.8, 0.85, 1.0, 0.1))
		"fog":
			_create_overlay(Color(0.6, 0.6, 0.6, 0.3))
		"sandstorm":
			_create_particles(80, Vector2(200, 50), Vector2(30, 30), Color(0.9, 0.8, 0.5, 0.5))
			_create_overlay(Color(0.8, 0.7, 0.4, 0.15))
		"clear":
			pass  # No effects

func _create_particles(amount: int, direction: Vector2, spread: Vector2, color: Color) -> void:
	_particles = CPUParticles2D.new()
	_particles.emitting = true
	_particles.amount = amount
	_particles.lifetime = 2.0
	_particles.direction = Vector3(direction.x, direction.y, 0)
	_particles.spread = 15.0
	_particles.initial_velocity_min = direction.length() * 0.8
	_particles.initial_velocity_max = direction.length() * 1.2
	_particles.gravity = Vector2(0, 0)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(400, 10)
	_particles.position = Vector2(0, -200)
	_particles.color = color
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.0
	add_child(_particles)

func _create_overlay(color: Color) -> void:
	if not _ui_layer:
		return
	_overlay = ColorRect.new()
	_overlay.color = color
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_overlay)

func _clear_effects() -> void:
	if _particles:
		_particles.queue_free()
		_particles = null
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_weather_type = "clear"

func _exit_tree() -> void:
	_clear_effects()
