extends Node
## AssetRegistry — centralized asset path references.
## All visual/audio paths live here so gameplay scripts never hardcode paths.
## To swap art later, update paths in this file (or point to a config resource).
##
## Asset Path Conventions:
##   Music:    res://assets/audio/music/<name>.wav
##   SFX:      res://assets/audio/sfx/<name>.wav
##   Sprites:  res://assets/sprites/<category>/<name>.png
##   Monsters: res://data/monsters/<name>.tres  (MonsterData resources)
##   Skills:   res://data/skills/<name>.tres     (SkillData resources)
##   UI:       res://assets/ui/<name>.tres
##
## AudioManager.play_sfx() silently skips missing files (ResourceLoader.exists guard).
## New SFX hooks can be added here and wired without audio files — they'll be silent
## until .wav files are supplied at the registered paths.

# ── Music ──
var music_town: String = "res://assets/audio/music/town_theme.wav"
var music_battle: String = "res://assets/audio/music/battle_theme.wav"

# ── SFX ──
var sfx_hit: String = "res://assets/audio/sfx/hit.wav"
var sfx_faint: String = "res://assets/audio/sfx/faint.wav"
var sfx_select: String = "res://assets/audio/sfx/select.wav"
var sfx_run: String = "res://assets/audio/sfx/run.wav"
var sfx_catch_success: String = "res://assets/audio/sfx/catch_success.wav"
var sfx_catch_fail: String = "res://assets/audio/sfx/catch_fail.wav"
var sfx_level_up: String = "res://assets/audio/sfx/level_up.wav"
var sfx_evolution: String = "res://assets/audio/sfx/evolution.wav"
var sfx_critical: String = "res://assets/audio/sfx/critical.wav"
var sfx_super_effective: String = "res://assets/audio/sfx/super_effective.wav"
var sfx_victory: String = "res://assets/audio/sfx/victory.wav"
var sfx_menu_open: String = "res://assets/audio/sfx/menu_open.wav"
var sfx_menu_close: String = "res://assets/audio/sfx/menu_close.wav"
var sfx_item_use: String = "res://assets/audio/sfx/item_use.wav"
var sfx_encounter: String = "res://assets/audio/sfx/encounter.wav"

# ── Player sprites ──
var player_boy_sprite: String = "res://assets/sprites/player/player_boy.png"
var player_girl_sprite: String = "res://assets/sprites/player/player_girl.png"

# ── NPC sprites ──
var npc_default_sprite: String = "res://assets/sprites/npcs/npc_default.png"

# ── Overworld ──
var tileset_town: String = "res://assets/sprites/overworld/tileset_town.png"
var tileset_route: String = "res://assets/sprites/overworld/tileset_placeholder.png"

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
