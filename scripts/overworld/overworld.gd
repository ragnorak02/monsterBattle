extends Node2D

var _current_encounter_monster: Resource = null
var _current_encounter_overworld_id: int = -1
var _current_encounter_level: int = 5

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player
@onready var npcs_container: Node2D = $NPCs
@onready var wild_monsters_container: Node2D = $WildMonsters
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_layer: CanvasLayer = $BattleLayer

var _auto_test: bool = false  # Set to true to enable auto-test
var _area_name_label: Label = null

# ── Area Configuration ──
const AREA_DATA: Dictionary = {
	"town": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 30,
		"tile_palette": "town",  # green grass, paths, water borders
		"npcs": [
			{"pos": Vector2(80, 80), "lines": ["Welcome to Monster Town!", "Go explore and catch monsters!"]},
			{"pos": Vector2(240, 100), "lines": ["I heard there are monsters\nin the tall grass nearby.", "Be careful out there!"]},
			{"pos": Vector2(100, 240), "lines": ["Press Tab to check your party.\nPress I to open inventory.", "Good luck on your adventure!"]},
		],
		"wild_monsters": [
			{"pos": Vector2(200, 160), "monster_id": 4, "level_min": 3, "level_max": 6},
			{"pos": Vector2(120, 100), "monster_id": 7, "level_min": 3, "level_max": 5},
			{"pos": Vector2(220, 220), "monster_id": 9, "level_min": 4, "level_max": 7},
			{"pos": Vector2(60, 200), "monster_id": 11, "level_min": 3, "level_max": 6},
			{"pos": Vector2(100, 50), "monster_id": 15, "level_min": 5, "level_max": 8},
			{"pos": Vector2(280, 100), "monster_id": 8, "level_min": 4, "level_max": 7},
			{"pos": Vector2(300, 250), "monster_id": 12, "level_min": 4, "level_max": 6},
			{"pos": Vector2(50, 300), "monster_id": 22, "level_min": 5, "level_max": 9},
		],
		"transitions": [
			{"edge": "east", "target_area": "route1", "spawn_offset": Vector2(32, 0)},
		],
	},
	"route1": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 35,
		"tile_palette": "route",  # darker, wilder terrain
		"npcs": [
			{"pos": Vector2(160, 160), "lines": ["This is Route 1!", "The monsters here are stronger."]},
		],
		"wild_monsters": [
			{"pos": Vector2(100, 80), "monster_id": 18, "level_min": 6, "level_max": 9},
			{"pos": Vector2(250, 120), "monster_id": 20, "level_min": 5, "level_max": 8},
			{"pos": Vector2(80, 240), "monster_id": 21, "level_min": 6, "level_max": 10},
			{"pos": Vector2(300, 200), "monster_id": 24, "level_min": 7, "level_max": 10},
			{"pos": Vector2(180, 300), "monster_id": 17, "level_min": 5, "level_max": 9},
			{"pos": Vector2(350, 100), "monster_id": 14, "level_min": 6, "level_max": 9},
			{"pos": Vector2(400, 280), "monster_id": 25, "level_min": 7, "level_max": 10},
			{"pos": Vector2(50, 350), "monster_id": 30, "level_min": 8, "level_max": 12},
		],
		"transitions": [
			{"edge": "west", "target_area": "town", "spawn_offset": Vector2(-32, 0)},
		],
	},
}

func _ready() -> void:
	var area_config: Dictionary = _get_area_config()
	_setup_tilemap(area_config)
	_spawn_npcs(area_config)
	_spawn_wild_monsters(area_config)
	_spawn_transition_zones(area_config)
	_update_player_sprite()
	_restore_player_position()
	_show_area_name()
	AudioManager.play_music(area_config["music"], false)
	if _auto_test:
		_run_auto_test()

func _get_area_config() -> Dictionary:
	var area: String = GameManager.current_area
	if AREA_DATA.has(area):
		return AREA_DATA[area]
	return AREA_DATA["town"]

func _restore_player_position() -> void:
	var saved_pos: Variant = GameManager.get_area_player_position(GameManager.current_area)
	if saved_pos != null:
		player.position = saved_pos as Vector2

func _setup_tilemap(area_config: Dictionary) -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)

	var source := TileSetAtlasSource.new()
	var tex := load("res://assets/sprites/overworld/tileset_placeholder.png") as Texture2D
	if tex:
		source.texture = tex
		source.texture_region_size = Vector2i(16, 16)
		source.create_tile(Vector2i(0, 0))
		source.create_tile(Vector2i(1, 0))
		source.create_tile(Vector2i(2, 0))
		tile_set.add_source(source, 0)

	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 2)
	tile_map.tile_set = tile_set

	var map_size: int = area_config.get("map_size", 30)
	var palette: String = area_config.get("tile_palette", "town")

	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			if palette == "route":
				# Route: no water border on transition edges, wilder layout
				var on_border: bool = abs(x) >= map_size - 2 or abs(y) >= map_size - 2
				if on_border:
					# Leave west edge open for transition back to town
					if x <= -(map_size - 2) and abs(y) < 5:
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
					else:
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
				elif (x + y) % 7 == 0 and abs(x) > 4 and abs(y) > 4:
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))  # Scattered rocks/water
				elif (x == 0 and abs(y) < 12) or (y == 0 and abs(x) < 12):
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
				else:
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			else:
				# Town: original layout, east edge open for transition
				if abs(x) >= map_size - 2 or abs(y) >= map_size - 2:
					if x >= map_size - 2 and abs(y) < 5:
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
					else:
						tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
				elif (x == 0 and abs(y) < 10) or (y == 0 and abs(x) < 10):
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
				else:
					tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	_add_water_collision(tile_set, source)

	# Apply color modulation for route areas
	if palette == "route":
		tile_map.modulate = Color(0.85, 0.9, 0.75)  # Slightly yellow-green, wilder
	else:
		tile_map.modulate = Color(1.0, 1.0, 1.0)

func _add_water_collision(_tile_set: TileSet, source: TileSetAtlasSource) -> void:
	var tile_data := source.get_tile_data(Vector2i(2, 0), 0)
	if tile_data:
		var polygon := PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
		])
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

func _spawn_npcs(area_config: Dictionary) -> void:
	var npc_scene := load("res://scenes/overworld/npc.tscn") as PackedScene
	if not npc_scene:
		return

	var npc_configs: Array = area_config.get("npcs", [])
	for config in npc_configs:
		var npc := npc_scene.instantiate()
		npc.position = config["pos"]
		npc.dialogue_lines = config["lines"]
		npcs_container.add_child(npc)

func _spawn_wild_monsters(area_config: Dictionary) -> void:
	var wild_scene := load("res://scenes/overworld/wild_monster.tscn") as PackedScene
	if not wild_scene:
		return

	var wild_configs: Array = area_config.get("wild_monsters", [])
	var current_area: String = GameManager.current_area

	for i in wild_configs.size():
		var config := wild_configs[i] as Dictionary
		if GameManager.is_area_monster_defeated(current_area, i + 1):
			continue
		var wild := wild_scene.instantiate()
		wild.position = config["pos"]
		wild.monster_data_id = config["monster_id"]
		wild.overworld_id = i + 1
		wild.level_min = config["level_min"]
		wild.level_max = config["level_max"]
		wild_monsters_container.add_child(wild)

func _spawn_transition_zones(area_config: Dictionary) -> void:
	var transitions: Array = area_config.get("transitions", [])
	var map_size: int = area_config.get("map_size", 30)

	for transition in transitions:
		var edge: String = transition["edge"]
		var target_area: String = transition["target_area"]
		var spawn_offset: Vector2 = transition["spawn_offset"]

		var zone := Area2D.new()
		zone.name = "Transition_%s" % target_area
		zone.collision_layer = 0
		zone.collision_mask = 1  # Player layer

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		match edge:
			"east":
				rect.size = Vector2(32, 160)
				zone.position = Vector2((map_size - 1) * 16, 0)
			"west":
				rect.size = Vector2(32, 160)
				zone.position = Vector2(-(map_size - 1) * 16, 0)
			"north":
				rect.size = Vector2(160, 32)
				zone.position = Vector2(0, -(map_size - 1) * 16)
			"south":
				rect.size = Vector2(160, 32)
				zone.position = Vector2(0, (map_size - 1) * 16)

		shape.shape = rect
		zone.add_child(shape)
		add_child(zone)

		zone.body_entered.connect(_on_transition_entered.bind(target_area, spawn_offset))

func _on_transition_entered(_body: Node2D, target_area: String, spawn_offset: Vector2) -> void:
	if GameManager.is_in_battle or GameManager.is_in_menu or GameManager.is_in_dialogue:
		return
	# Save current position
	GameManager.set_area_player_position(GameManager.current_area, player.position)
	# Set target area and spawn position
	GameManager.current_area = target_area

	# Calculate spawn position for the target area (opposite edge)
	var target_config: Dictionary = AREA_DATA.get(target_area, {})
	var target_map_size: int = target_config.get("map_size", 30)
	var spawn_pos: Vector2
	if spawn_offset.x > 0:
		# Entering from west side
		spawn_pos = Vector2(-(target_map_size - 4) * 16, player.position.y)
	elif spawn_offset.x < 0:
		# Entering from east side
		spawn_pos = Vector2((target_map_size - 4) * 16, player.position.y)
	elif spawn_offset.y > 0:
		spawn_pos = Vector2(player.position.x, -(target_map_size - 4) * 16)
	else:
		spawn_pos = Vector2(player.position.x, (target_map_size - 4) * 16)

	GameManager.set_area_player_position(target_area, spawn_pos)
	print("[OVERWORLD] Transitioning to %s" % target_area)
	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")

func _show_area_name() -> void:
	var area_names: Dictionary = {
		"town": "Monster Town",
		"route1": "Route 1",
	}
	var display_name: String = area_names.get(GameManager.current_area, GameManager.current_area)

	_area_name_label = Label.new()
	_area_name_label.text = display_name
	_area_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_name_label.add_theme_font_size_override("font_size", 14)
	_area_name_label.position = Vector2(240, 10)
	_area_name_label.size = Vector2(160, 30)
	_area_name_label.modulate = Color(1, 1, 1, 1)
	ui_layer.add_child(_area_name_label)

	# Fade out area name after 2 seconds
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_area_name_label, "modulate:a", 0.0, 1.0)

func _update_player_sprite() -> void:
	var sprite_path := "res://assets/sprites/player/player_%s.png" % GameManager.player_gender
	var tex := load(sprite_path) as Texture2D
	if tex and player:
		var spr := player.get_node("Sprite2D") as Sprite2D
		if spr:
			spr.texture = tex

# --- Encounter flow: interact → pick monster → battle ---

func show_encounter(monster_data: Resource, overworld_id: int, monster_level: int = 5) -> void:
	if GameManager.is_in_battle or GameManager.is_in_dialogue:
		return
	print("Encounter: ", str(monster_data.get("monster_name")), " Lv.", monster_level)
	_current_encounter_monster = monster_data
	_current_encounter_overworld_id = overworld_id
	_current_encounter_level = monster_level

	var encounter_scene := load("res://scenes/ui/encounter_ui.tscn") as PackedScene
	if encounter_scene:
		var encounter := encounter_scene.instantiate()
		encounter.setup(monster_data, monster_level)
		encounter.monster_chosen.connect(_on_encounter_monster_chosen)
		encounter.cancelled.connect(_on_encounter_cancelled)
		ui_layer.add_child(encounter)

func _on_encounter_monster_chosen(party_index: int) -> void:
	# Swap chosen monster to front of party for the battle
	if party_index > 0 and party_index < GameManager.player_party.size():
		var chosen := GameManager.player_party[party_index]
		GameManager.player_party.remove_at(party_index)
		GameManager.player_party.insert(0, chosen)

	start_battle(_current_encounter_monster, _current_encounter_overworld_id, _current_encounter_level)

func _on_encounter_cancelled() -> void:
	_current_encounter_monster = null
	_current_encounter_overworld_id = -1
	_current_encounter_level = 5

# --- Battle ---

func start_battle(monster_data: Resource, overworld_id: int, monster_level: int = 5) -> void:
	if GameManager.is_in_battle:
		return
	GameManager.is_in_battle = true
	print("Starting battle with: ", str(monster_data.get("monster_name")), " Lv.", monster_level)

	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	if battle_scene:
		var battle := battle_scene.instantiate()
		battle.wild_monster_data = monster_data
		battle.wild_overworld_id = overworld_id
		battle.wild_monster_level = monster_level
		battle.battle_ended.connect(_on_battle_ended)
		battle_layer.add_child(battle)
	else:
		print("ERROR: Failed to load battle scene!")
		GameManager.is_in_battle = false

func _on_battle_ended(result: String, overworld_id: int) -> void:
	GameManager.is_in_battle = false
	var removed := (result == "win" or result == "catch")
	if removed:
		GameManager.mark_area_monster_defeated(GameManager.current_area, overworld_id)

	# Notify the wild monster
	for child in wild_monsters_container.get_children():
		if child.has_method("get_overworld_id") and child.get_overworld_id() == overworld_id:
			if child.has_method("on_battle_ended"):
				child.on_battle_ended(removed)
			break

func _show_dialogue(lines: Array) -> void:
	var dialogue_scene := load("res://scenes/overworld/dialogue_box.tscn") as PackedScene
	if dialogue_scene:
		var dialogue := dialogue_scene.instantiate()
		dialogue.set_lines(lines)
		ui_layer.add_child(dialogue)

func _input(event: InputEvent) -> void:
	# Debug: F1 to start a test battle (skips encounter UI)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		var test_monster := MonsterDB.get_random_wild_monster()
		if test_monster:
			show_encounter(test_monster, -1)

func _run_auto_test() -> void:
	print("[AUTO-TEST] Starting auto battle test in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	# Pick a random wild monster to fight
	var test_monster: Resource = MonsterDB.get_monster(4)  # Flamander
	if not test_monster:
		print("[AUTO-TEST] ERROR: Could not load monster data!")
		return
	print("[AUTO-TEST] Triggering encounter with: ", str(test_monster.get("monster_name")))
	# Skip the encounter UI and go straight to battle
	start_battle(test_monster, -1)
