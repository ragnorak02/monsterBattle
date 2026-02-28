extends Control

@onready var bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var _cached_style: StyleBoxFlat

func _ready() -> void:
	_cached_style = StyleBoxFlat.new()
	_cached_style.bg_color = Color(0.2, 0.4, 0.9)
	if bar:
		bar.max_value = 100
		bar.value = 0
		bar.add_theme_stylebox_override("fill", _cached_style)

func setup(current_xp: int, xp_to_next: int) -> void:
	if xp_to_next <= 0:
		if bar:
			bar.value = 100
		if label:
			label.text = "MAX"
		return
	var pct := (float(current_xp) / float(xp_to_next)) * 100.0
	if bar:
		bar.value = pct
	if label:
		label.text = "EXP %d / %d" % [current_xp, xp_to_next]
