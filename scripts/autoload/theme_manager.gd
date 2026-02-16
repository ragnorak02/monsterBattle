extends Node
## ThemeManager — builds and applies a consistent UI theme at startup.
## Change colors / fonts here to restyle the entire game.

var game_theme: Theme

# ── Color Palette (bright, playful, Zelda-like) ──
const COL_BG_DARK := Color(0.12, 0.15, 0.22, 0.95)        # Dark blue-gray panel bg
const COL_BG_MED := Color(0.18, 0.22, 0.32, 0.95)          # Medium panel bg
const COL_BG_LIGHT := Color(0.25, 0.30, 0.42, 0.90)        # Lighter panel
const COL_BORDER := Color(0.85, 0.75, 0.45, 1.0)            # Gold border
const COL_BORDER_FOCUS := Color(1.0, 0.9, 0.4, 1.0)         # Bright gold (focused)
const COL_TEXT := Color(1.0, 1.0, 1.0, 1.0)                 # White text
const COL_TEXT_DIM := Color(0.7, 0.7, 0.7, 1.0)             # Dimmed text
const COL_ACCENT := Color(0.3, 0.7, 1.0, 1.0)               # Blue accent
const COL_BTN_NORMAL := Color(0.2, 0.28, 0.42, 1.0)         # Button bg
const COL_BTN_HOVER := Color(0.25, 0.35, 0.55, 1.0)         # Button hover
const COL_BTN_PRESSED := Color(0.15, 0.2, 0.35, 1.0)        # Button pressed
const COL_BTN_FOCUS := Color(0.28, 0.38, 0.58, 1.0)         # Button focused
const COL_BTN_DISABLED := Color(0.15, 0.18, 0.25, 0.8)      # Button disabled
const COL_HP_GREEN := Color(0.2, 0.8, 0.2, 1.0)
const COL_HP_YELLOW := Color(0.9, 0.7, 0.1, 1.0)
const COL_HP_RED := Color(0.9, 0.2, 0.2, 1.0)
const COL_PROGRESS_BG := Color(0.1, 0.12, 0.18, 1.0)

const BORDER_WIDTH := 2
const CORNER_RADIUS := 4

func _ready() -> void:
	game_theme = _build_theme()
	# Apply theme to root viewport so all UI inherits it
	get_tree().root.theme = game_theme

func _build_theme() -> Theme:
	var theme := Theme.new()

	# Default font size
	theme.set_default_font_size(12)

	# ── Button ──
	theme.set_stylebox("normal", "Button", _make_button_box(COL_BTN_NORMAL))
	theme.set_stylebox("hover", "Button", _make_button_box(COL_BTN_HOVER))
	theme.set_stylebox("pressed", "Button", _make_button_box(COL_BTN_PRESSED))
	theme.set_stylebox("focus", "Button", _make_button_box(COL_BTN_FOCUS, true))
	theme.set_stylebox("disabled", "Button", _make_button_box(COL_BTN_DISABLED))
	theme.set_color("font_color", "Button", COL_TEXT)
	theme.set_color("font_hover_color", "Button", Color(1, 1, 0.8))
	theme.set_color("font_pressed_color", "Button", COL_ACCENT)
	theme.set_color("font_focus_color", "Button", Color(1, 1, 0.8))
	theme.set_color("font_disabled_color", "Button", COL_TEXT_DIM)
	theme.set_constant("h_separation", "Button", 8)

	# ── PanelContainer ──
	theme.set_stylebox("panel", "PanelContainer", _make_panel_box(COL_BG_DARK))

	# ── Panel ──
	theme.set_stylebox("panel", "Panel", _make_panel_box(COL_BG_MED))

	# ── Label ──
	theme.set_color("font_color", "Label", COL_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 12)

	# ── RichTextLabel ──
	theme.set_color("default_color", "RichTextLabel", COL_TEXT)

	# ── ProgressBar ──
	theme.set_stylebox("background", "ProgressBar", _make_progress_bg())
	theme.set_stylebox("fill", "ProgressBar", _make_progress_fill(COL_HP_GREEN))

	return theme

func _make_button_box(bg_color: Color, focused: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.corner_radius_top_left = CORNER_RADIUS
	box.corner_radius_top_right = CORNER_RADIUS
	box.corner_radius_bottom_left = CORNER_RADIUS
	box.corner_radius_bottom_right = CORNER_RADIUS
	box.border_width_left = BORDER_WIDTH
	box.border_width_right = BORDER_WIDTH
	box.border_width_top = BORDER_WIDTH
	box.border_width_bottom = BORDER_WIDTH
	box.border_color = COL_BORDER_FOCUS if focused else COL_BORDER
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box

func _make_panel_box(bg_color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_color
	box.corner_radius_top_left = CORNER_RADIUS + 2
	box.corner_radius_top_right = CORNER_RADIUS + 2
	box.corner_radius_bottom_left = CORNER_RADIUS + 2
	box.corner_radius_bottom_right = CORNER_RADIUS + 2
	box.border_width_left = BORDER_WIDTH
	box.border_width_right = BORDER_WIDTH
	box.border_width_top = BORDER_WIDTH
	box.border_width_bottom = BORDER_WIDTH
	box.border_color = COL_BORDER
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box

func _make_progress_bg() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = COL_PROGRESS_BG
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.border_color = COL_BORDER
	return box

func _make_progress_fill(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = 2
	box.corner_radius_top_right = 2
	box.corner_radius_bottom_left = 2
	box.corner_radius_bottom_right = 2
	return box
