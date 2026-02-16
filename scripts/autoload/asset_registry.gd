extends Node
## AssetRegistry — centralized asset path references.
## All visual/audio paths live here so gameplay scripts never hardcode paths.
## To swap art later, update paths in this file (or point to a config resource).

# ── Music ──
var music_town: String = "res://assets/audio/music/town_theme.wav"
var music_battle: String = "res://assets/audio/music/battle_theme.wav"

# ── SFX ──
var sfx_hit: String = "res://assets/audio/sfx/hit.wav"
var sfx_faint: String = "res://assets/audio/sfx/faint.wav"
var sfx_select: String = "res://assets/audio/sfx/select.wav"
var sfx_cancel: String = "res://assets/audio/sfx/cancel.wav"
var sfx_encounter: String = "res://assets/audio/sfx/encounter.wav"
var sfx_run: String = "res://assets/audio/sfx/run.wav"

# ── Player sprites ──
var player_boy_sprite: String = "res://assets/sprites/player/player_boy.png"
var player_girl_sprite: String = "res://assets/sprites/player/player_girl.png"

# ── NPC sprites ──
var npc_default_sprite: String = "res://assets/sprites/npcs/npc_default.png"

# ── Overworld ──
var tileset_texture: String = "res://assets/sprites/overworld/tileset_placeholder.png"

# ── UI ──
var ui_theme: String = "res://assets/ui/game_theme.tres"

# ── Helpers ──
func get_player_sprite_path() -> String:
	if GameManager.player_gender == "girl":
		return player_girl_sprite
	return player_boy_sprite

func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("AssetRegistry: texture not found: " + path)
	return null

func load_theme() -> Theme:
	if ResourceLoader.exists(ui_theme):
		return load(ui_theme) as Theme
	push_warning("AssetRegistry: theme not found: " + ui_theme)
	return null
