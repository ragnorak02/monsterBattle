extends Control

@onready var bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var _target_value: float = 100.0
var _current_display: float = 100.0
const DRAIN_SPEED := 80.0  # HP per second visual drain

func _ready() -> void:
	if bar:
		bar.max_value = 100
		bar.value = 100

func setup(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var pct := (float(current_hp) / float(max_hp)) * 100.0
	_current_display = pct
	_target_value = pct
	if bar:
		bar.value = pct
	_update_color()
	_update_label(current_hp, max_hp)

func animate_to(current_hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	_target_value = (float(current_hp) / float(max_hp)) * 100.0
	_update_label(current_hp, max_hp)

func _process(delta: float) -> void:
	if not bar:
		return
	if abs(_current_display - _target_value) > 0.1:
		if _current_display > _target_value:
			_current_display = max(_target_value, _current_display - DRAIN_SPEED * delta)
		else:
			_current_display = min(_target_value, _current_display + DRAIN_SPEED * delta)
		bar.value = _current_display
		_update_color()

func _update_color() -> void:
	if not bar:
		return
	var style := StyleBoxFlat.new()
	if _current_display > 50:
		style.bg_color = Color(0.2, 0.8, 0.2)  # Green
	elif _current_display > 25:
		style.bg_color = Color(0.9, 0.7, 0.1)  # Yellow
	else:
		style.bg_color = Color(0.9, 0.2, 0.2)  # Red
	bar.add_theme_stylebox_override("fill", style)

func _update_label(current_hp: int, max_hp: int) -> void:
	if label:
		label.text = "%d / %d" % [current_hp, max_hp]
