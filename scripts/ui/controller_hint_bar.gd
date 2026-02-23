extends PanelContainer
## Reusable controller hint bar — anchored to bottom of screen.
## Usage: hint_bar.set_hints([{"icon": "btn_a", "label": "Select"}, ...])

const ICON_DIR := "res://assets/ui/controller/"

var _icon_cache: Dictionary = {}
var _hbox: HBoxContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox = get_node("MarginContainer/HBox")

func set_hints(hints: Array) -> void:
	for child in _hbox.get_children():
		child.queue_free()
	for hint in hints:
		var pair := HBoxContainer.new()
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_theme_constant_override("separation", 4)
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(12, 12)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = _load_icon(hint["icon"])
		pair.add_child(icon_rect)
		var lbl := Label.new()
		lbl.text = hint["label"]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 10)
		pair.add_child(lbl)
		_hbox.add_child(pair)

func _load_icon(icon_name: String) -> Texture2D:
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name]
	var path := ICON_DIR + icon_name + ".png"
	var tex := load(path) as Texture2D
	if tex:
		_icon_cache[icon_name] = tex
	return tex
