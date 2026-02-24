extends CanvasLayer

@onready var map_canvas: Control = $Panel/MarginContainer/VBox/MapCanvas
@onready var hint_bar: PanelContainer = $ControllerHintBar

const MAP_POSITIONS: Dictionary = {
	"town": Vector2(160, 260),
	"route1": Vector2(160, 190),
	"route2": Vector2(160, 120),
	"town2": Vector2(160, 50),
}

const MAP_CONNECTIONS: Array = [
	["town", "route1"],
	["route1", "route2"],
	["route2", "town2"],
]

const AREA_DISPLAY_NAMES: Dictionary = {
	"town": "Monster Town",
	"route1": "Route 1",
	"route2": "Route 2",
	"town2": "Coral City",
}

func _ready() -> void:
	GameManager.is_in_menu = true
	if map_canvas:
		map_canvas.draw.connect(_on_map_draw)
		map_canvas.queue_redraw()
	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_b", "label": "Close"},
		])

func _on_map_draw() -> void:
	if not map_canvas:
		return
	var current_area: String = GameManager.current_area

	# Draw connections (lines)
	for conn: Array in MAP_CONNECTIONS:
		var from_key: String = str(conn[0])
		var to_key: String = str(conn[1])
		if MAP_POSITIONS.has(from_key) and MAP_POSITIONS.has(to_key):
			var from_pos: Vector2 = MAP_POSITIONS[from_key]
			var to_pos: Vector2 = MAP_POSITIONS[to_key]
			map_canvas.draw_line(from_pos, to_pos, Color(0.4, 0.4, 0.4), 2.0)

	# Draw area dots and labels
	for area_key: String in MAP_POSITIONS:
		var pos: Vector2 = MAP_POSITIONS[area_key]
		var color: Color
		if area_key == current_area:
			color = Color(1.0, 0.84, 0.0)  # Gold for current
		elif area_key.begins_with("town"):
			color = Color(0.3, 0.5, 1.0)  # Blue for towns
		else:
			color = Color(0.3, 0.8, 0.3)  # Green for routes
		map_canvas.draw_circle(pos, 8.0, color)

		# Label
		var display_name: String = AREA_DISPLAY_NAMES.get(area_key, area_key)
		if area_key == current_area:
			display_name = "> " + display_name
		var font := ThemeDB.fallback_font
		if font:
			map_canvas.draw_string(font, pos + Vector2(14, 5), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameManager.is_in_menu = false
	queue_free()
