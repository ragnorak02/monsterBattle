extends Node

signal scene_changed(scene_name: String)

var _scene_container: Node = null
var _fade_overlay: ColorRect = null
var _current_scene: Node = null
var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(container: Node, overlay: ColorRect) -> void:
	_scene_container = container
	_fade_overlay = overlay
	if _fade_overlay:
		_fade_overlay.color = Color(0, 0, 0, 0)

func change_scene(scene_path: String, with_fade: bool = true) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if with_fade and _fade_overlay:
		await _fade_out()

	if _current_scene:
		_current_scene.queue_free()
		_current_scene = null

	var scene_resource := load(scene_path) as PackedScene
	if scene_resource:
		_current_scene = scene_resource.instantiate()
		_scene_container.add_child(_current_scene)
		scene_changed.emit(scene_path)

	if with_fade and _fade_overlay:
		await _fade_in()

	_is_transitioning = false

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color:a", 1.0, 0.3)
	await tween.finished

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color:a", 0.0, 0.3)
	await tween.finished
