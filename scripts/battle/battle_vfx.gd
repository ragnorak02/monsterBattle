class_name BattleVFX

## Battle visual effects — crit flash, damage popup, super effective flash.
## All effects use Tween + temporary Control nodes (no shaders/particles).

static func _is_flash_reduced() -> bool:
	var am := Engine.get_main_loop().root.get_node_or_null("AccessibilityManager")
	return am != null and am.get("reduce_flash") == true

static func crit_flash(parent: Control) -> void:
	if not parent or not parent.is_inside_tree():
		return
	if _is_flash_reduced():
		return
	var overlay := ColorRect.new()
	overlay.color = Color(1.0, 1.0, 0.7, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	var tween := parent.create_tween()
	tween.tween_property(overlay, "color:a", 0.6, 0.08)
	tween.tween_property(overlay, "color:a", 0.0, 0.12)
	tween.tween_callback(overlay.queue_free)

static func super_effective_flash(parent: Control) -> void:
	if not parent or not parent.is_inside_tree():
		return
	if _is_flash_reduced():
		return
	var overlay := ColorRect.new()
	overlay.color = Color(1.0, 0.4, 0.15, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	var tween := parent.create_tween()
	tween.tween_property(overlay, "color:a", 0.5, 0.08)
	tween.tween_property(overlay, "color:a", 0.0, 0.14)
	tween.tween_callback(overlay.queue_free)

static func damage_popup(parent: Control, amount: int, is_crit: bool, effectiveness: String) -> void:
	if not parent or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Size and color based on hit type
	var font_size: int = 14
	var color := Color.WHITE
	if is_crit:
		font_size = 18
		color = Color(1.0, 0.9, 0.2)
	elif effectiveness == "super_effective":
		font_size = 16
		color = Color(1.0, 0.5, 0.2)
	elif effectiveness == "not_very_effective":
		font_size = 12
		color = Color(0.6, 0.6, 0.6)

	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	# Position at center-top of parent
	label.position = Vector2(parent.size.x / 2.0 - 16.0, parent.size.y * 0.3)
	parent.add_child(label)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 24.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

static func start_status_pulse(status_label: Label) -> void:
	if not status_label or not status_label.is_inside_tree():
		return
	# Only start if not already pulsing (check for existing meta)
	if status_label.has_meta("_vfx_pulse_tween"):
		return
	var tween := status_label.create_tween()
	tween.set_loops()
	tween.tween_property(status_label, "modulate:a", 0.5, 0.6)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.6)
	status_label.set_meta("_vfx_pulse_tween", tween)

static func stop_status_pulse(status_label: Label) -> void:
	if not status_label:
		return
	if status_label.has_meta("_vfx_pulse_tween"):
		var tween: Tween = status_label.get_meta("_vfx_pulse_tween")
		if tween and tween.is_valid():
			tween.kill()
		status_label.remove_meta("_vfx_pulse_tween")
	status_label.modulate.a = 1.0
