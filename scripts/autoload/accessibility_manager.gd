extends Node
## AccessibilityManager — user accessibility preferences.
## Persisted to user://accessibility.cfg via ConfigFile.

var screenshake_enabled: bool = true
var large_text_mode: bool = false
var reduce_flash: bool = false
var colorblind_mode: bool = false

const CONFIG_PATH := "user://accessibility.cfg"
const SECTION := "accessibility"

func _ready() -> void:
	_load_config()
	_apply_settings()

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	screenshake_enabled = cfg.get_value(SECTION, "screenshake_enabled", true)
	large_text_mode = cfg.get_value(SECTION, "large_text_mode", false)
	reduce_flash = cfg.get_value(SECTION, "reduce_flash", false)
	colorblind_mode = cfg.get_value(SECTION, "colorblind_mode", false)

func save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "screenshake_enabled", screenshake_enabled)
	cfg.set_value(SECTION, "large_text_mode", large_text_mode)
	cfg.set_value(SECTION, "reduce_flash", reduce_flash)
	cfg.set_value(SECTION, "colorblind_mode", colorblind_mode)
	cfg.save(CONFIG_PATH)

func _apply_settings() -> void:
	if large_text_mode:
		_set_large_text(true)

func _set_large_text(enabled: bool) -> void:
	if ThemeManager and ThemeManager.game_theme:
		var size: int = 14 if enabled else 12
		ThemeManager.game_theme.set_default_font_size(size)
		ThemeManager.game_theme.set_font_size("font_size", "Label", size)

func set_screenshake(enabled: bool) -> void:
	screenshake_enabled = enabled
	save_config()

func set_large_text(enabled: bool) -> void:
	large_text_mode = enabled
	_set_large_text(enabled)
	save_config()

func set_reduce_flash(enabled: bool) -> void:
	reduce_flash = enabled
	save_config()

func set_colorblind_mode(enabled: bool) -> void:
	colorblind_mode = enabled
	save_config()
