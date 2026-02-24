extends Node

signal cutscene_finished

var _steps: Array = []
var _camera: Camera2D = null
var _ui_layer: CanvasLayer = null

func play(steps: Array, camera: Camera2D, p_ui_layer: CanvasLayer) -> void:
	_steps = steps
	_camera = camera
	_ui_layer = p_ui_layer
	GameManager.is_in_dialogue = true
	_execute_steps()

func _execute_steps() -> void:
	for step in _steps:
		if not is_instance_valid(self):
			return
		var step_type: String = str(step.get("type", ""))
		match step_type:
			"dialogue":
				await _step_dialogue(step)
			"wait":
				await _step_wait(step)
			"camera_move":
				await _step_camera_move(step)
			"screen_flash":
				await _step_screen_flash(step)
			"fade_out":
				await _step_fade(true, step)
			"fade_in":
				await _step_fade(false, step)
			"play_sfx":
				_step_play_sfx(step)
			"play_music":
				_step_play_music(step)
	_finish()

func _step_dialogue(step: Dictionary) -> void:
	var dialogue_scene := load("res://scenes/overworld/dialogue_box.tscn") as PackedScene
	if not dialogue_scene or not _ui_layer:
		return
	var dialogue := dialogue_scene.instantiate()
	var lines: Array = step.get("lines", ["..."])
	dialogue.set_lines(lines)
	_ui_layer.add_child(dialogue)
	await dialogue.tree_exited

func _step_wait(step: Dictionary) -> void:
	var duration: float = float(step.get("duration", 1.0))
	await get_tree().create_timer(duration).timeout

func _step_camera_move(step: Dictionary) -> void:
	if not _camera:
		return
	var target: Vector2 = step.get("target", _camera.position) as Vector2
	var duration: float = float(step.get("duration", 1.0))
	var tween := create_tween()
	tween.tween_property(_camera, "position", target, duration)
	await tween.finished

func _step_screen_flash(step: Dictionary) -> void:
	if not _ui_layer:
		return
	var flash_color: Color = step.get("color", Color.WHITE) as Color
	var duration: float = float(step.get("duration", 0.3))
	var rect := ColorRect.new()
	rect.color = flash_color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(rect)
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
	rect.queue_free()

func _step_fade(fade_out: bool, step: Dictionary) -> void:
	if not _ui_layer:
		return
	var duration: float = float(step.get("duration", 0.5))
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if fade_out:
		rect.modulate.a = 0.0
	else:
		rect.modulate.a = 1.0
	_ui_layer.add_child(rect)
	var tween := create_tween()
	if fade_out:
		tween.tween_property(rect, "modulate:a", 1.0, duration)
	else:
		tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
	rect.queue_free()

func _step_play_sfx(step: Dictionary) -> void:
	var sfx_path: String = str(step.get("path", ""))
	if sfx_path != "" and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(sfx_path)

func _step_play_music(step: Dictionary) -> void:
	var music_path: String = str(step.get("path", ""))
	if music_path != "":
		AudioManager.play_music(music_path)

func _finish() -> void:
	GameManager.is_in_dialogue = false
	cutscene_finished.emit()
	queue_free()
