extends Control

@onready var bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var _cached_style: StyleBoxFlat
var _target_value: float = 0.0
var _current_display: float = 0.0
const FILL_SPEED := 60.0  # Percent per second

func _ready() -> void:
	_cached_style = StyleBoxFlat.new()
	_cached_style.bg_color = Color(0.2, 0.4, 0.9)
	if bar:
		bar.max_value = 100
		bar.value = 0
		bar.add_theme_stylebox_override("fill", _cached_style)

func setup(current_xp: int, xp_to_next: int) -> void:
	if xp_to_next <= 0:
		_target_value = 100.0
		_current_display = 100.0
		if bar:
			bar.value = 100
		if label:
			label.text = "MAX"
		set_process(false)
		return
	var pct := (float(current_xp) / float(xp_to_next)) * 100.0
	_target_value = pct
	_current_display = pct
	if bar:
		bar.value = pct
	if label:
		label.text = "EXP %d / %d" % [current_xp, xp_to_next]
	set_process(false)

func animate_to(current_xp: int, xp_to_next: int) -> void:
	if xp_to_next <= 0:
		_target_value = 100.0
		if label:
			label.text = "MAX"
		set_process(true)
		return
	_target_value = (float(current_xp) / float(xp_to_next)) * 100.0
	if label:
		label.text = "EXP %d / %d" % [current_xp, xp_to_next]
	set_process(true)

func _process(delta: float) -> void:
	if not bar:
		return
	if abs(_current_display - _target_value) > 0.1:
		if _current_display < _target_value:
			_current_display = min(_target_value, _current_display + FILL_SPEED * delta)
		else:
			_current_display = max(_target_value, _current_display - FILL_SPEED * delta)
		bar.value = _current_display
	else:
		_current_display = _target_value
		bar.value = _current_display
		set_process(false)
