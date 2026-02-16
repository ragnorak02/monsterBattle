extends Node2D

var _current_encounter_monster: Resource = null
var _current_encounter_overworld_id: int = -1

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $Player
@onready var npcs_container: Node2D = $NPCs
@onready var wild_monsters_container: Node2D = $WildMonsters
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_layer: CanvasLayer = $BattleLayer

var _auto_test: bool = false  # Set to true to enable auto-test

func _ready() -> void:
	_setup_tilemap()
	_spawn_npcs()
	_spawn_wild_monsters()
	_update_player_sprite()
	AudioManager.play_music("res://assets/audio/music/town_theme.wav", false)
	if _auto_test:
		_run_auto_test()

func _setup_tilemap() -> void:
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

	var map_size := 30
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			if abs(x) >= map_size - 2 or abs(y) >= map_size - 2:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
			elif (x == 0 and abs(y) < 10) or (y == 0 and abs(x) < 10):
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
			else:
				tile_map.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	_add_water_collision(tile_set, source)

func _add_water_collision(_tile_set: TileSet, source: TileSetAtlasSource) -> void:
	var tile_data := source.get_tile_data(Vector2i(2, 0), 0)
	if tile_data:
		var polygon := PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
		])
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, polygon)

func _spawn_npcs() -> void:
	var npc_scene := load("res://scenes/overworld/npc.tscn") as PackedScene
	if not npc_scene:
		return

	var npc_configs := [
		{"pos": Vector2(80, 80), "lines": ["Welcome to Monster Town!", "Go explore and catch monsters!"]},
		{"pos": Vector2(240, 100), "lines": ["I heard there are monsters\nin the tall grass nearby.", "Be careful out there!"]},
		{"pos": Vector2(100, 240), "lines": ["Press Tab to check your party.", "Good luck on your adventure!"]},
	]

	for config in npc_configs:
		var npc := npc_scene.instantiate()
		npc.position = config["pos"]
		npc.dialogue_lines = config["lines"]
		npcs_container.add_child(npc)

func _spawn_wild_monsters() -> void:
	var wild_scene := load("res://scenes/overworld/wild_monster.tscn") as PackedScene
	if not wild_scene:
		return

	# Place wild monsters - some nearby for easy testing
	var wild_configs := [
		{"pos": Vector2(200, 160), "monster_id": 4},
		{"pos": Vector2(120, 100), "monster_id": 7},
		{"pos": Vector2(220, 220), "monster_id": 9},
		{"pos": Vector2(60, 200), "monster_id": 11},
		{"pos": Vector2(100, 50), "monster_id": 15},
		{"pos": Vector2(280, 100), "monster_id": 8},
		{"pos": Vector2(300, 250), "monster_id": 12},
		{"pos": Vector2(50, 300), "monster_id": 22},
	]

	for i in wild_configs.size():
		var config := wild_configs[i] as Dictionary
		if GameManager.is_monster_defeated(i + 1):
			continue
		var wild := wild_scene.instantiate()
		wild.position = config["pos"]
		wild.monster_data_id = config["monster_id"]
		wild.overworld_id = i + 1
		wild_monsters_container.add_child(wild)

func _update_player_sprite() -> void:
	var sprite_path := "res://assets/sprites/player/player_%s.png" % GameManager.player_gender
	var tex := load(sprite_path) as Texture2D
	if tex and player:
		var spr := player.get_node("Sprite2D") as Sprite2D
		if spr:
			spr.texture = tex

# --- Encounter flow: interact → pick monster → battle ---

func show_encounter(monster_data: Resource, overworld_id: int) -> void:
	if GameManager.is_in_battle or GameManager.is_in_dialogue:
		return
	print("Encounter: ", str(monster_data.get("monster_name")))
	_current_encounter_monster = monster_data
	_current_encounter_overworld_id = overworld_id

	var encounter_scene := load("res://scenes/ui/encounter_ui.tscn") as PackedScene
	if encounter_scene:
		var encounter := encounter_scene.instantiate()
		encounter.setup(monster_data)
		encounter.monster_chosen.connect(_on_encounter_monster_chosen)
		encounter.cancelled.connect(_on_encounter_cancelled)
		ui_layer.add_child(encounter)

func _on_encounter_monster_chosen(party_index: int) -> void:
	# Swap chosen monster to front of party for the battle
	if party_index > 0 and party_index < GameManager.player_party.size():
		var chosen := GameManager.player_party[party_index]
		GameManager.player_party.remove_at(party_index)
		GameManager.player_party.insert(0, chosen)

	start_battle(_current_encounter_monster, _current_encounter_overworld_id)

func _on_encounter_cancelled() -> void:
	_current_encounter_monster = null
	_current_encounter_overworld_id = -1

# --- Battle ---

func start_battle(monster_data: Resource, overworld_id: int) -> void:
	if GameManager.is_in_battle:
		return
	GameManager.is_in_battle = true
	print("Starting battle with: ", str(monster_data.get("monster_name")))

	var battle_scene := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	if battle_scene:
		var battle := battle_scene.instantiate()
		battle.wild_monster_data = monster_data
		battle.wild_overworld_id = overworld_id
		battle.battle_ended.connect(_on_battle_ended)
		battle_layer.add_child(battle)
	else:
		print("ERROR: Failed to load battle scene!")
		GameManager.is_in_battle = false

func _on_battle_ended(result: String, overworld_id: int) -> void:
	GameManager.is_in_battle = false
	var defeated := (result == "win")
	if defeated:
		GameManager.mark_monster_defeated(overworld_id)

	# Notify the wild monster
	for child in wild_monsters_container.get_children():
		if child.has_method("get_overworld_id") and child.get_overworld_id() == overworld_id:
			if child.has_method("on_battle_ended"):
				child.on_battle_ended(defeated)
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
