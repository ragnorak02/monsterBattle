extends Node2D

var _current_encounter_monster: Resource = null
var _current_encounter_overworld_id: int = -1
var _current_encounter_level: int = 5
var _route_layout: Dictionary = {}

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var player: CharacterBody2D = $YSortRoot/Player
@onready var npcs_container: Node2D = $YSortRoot/NPCs
@onready var follower: Node2D = $YSortRoot/Follower
@onready var wild_monsters_container: Node2D = $YSortRoot/WildMonsters
@onready var ui_layer: CanvasLayer = $UILayer
@onready var battle_layer: CanvasLayer = $BattleLayer
@onready var hint_bar: PanelContainer = $UILayer/ControllerHintBar

var _auto_test: bool = false  # Set to true to enable auto-test
var _area_name_label: Label = null
var _canvas_modulate: CanvasModulate = null
var _weather_system: Node2D = null

# ── Area Configuration ──
const AREA_DATA: Dictionary = {
	"town": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 40,
		"tile_palette": "town",
		"safe_zone": true,
		"buildings": [
			{"type": "hospital", "pos": Vector2i(-14, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Your monsters are fully healed!"], "bubble": "Need healing?",
						"dialogue": [
							{"id": "start", "text": "Welcome to the Monster Town\nHospital! Want me to heal\nyour monsters?", "speaker": "Nurse Joy", "choices": [
								{"label": "Yes, please", "next": "heal"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "heal", "text": "All better! Your monsters\nare fully healed.", "speaker": "Nurse Joy", "action": "heal_party"},
							{"id": "bye", "text": "Take care out there!", "speaker": "Nurse Joy"},
						]},
				],
				"interior_pc_terminals": [{"pos": Vector2(48, -32)}],
			},
			{"type": "shop", "pos": Vector2i(6, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Welcome to my shop!"], "bubble": "Buy something!",
						"dialogue": [
							{"id": "start", "text": "Welcome! Care to browse my wares?", "speaker": "Shopkeeper", "choices": [
								{"label": "Browse wares", "next": "shop"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "shop", "text": "Take a look!", "speaker": "Shopkeeper", "action": "open_shop"},
							{"id": "bye", "text": "Come back anytime!", "speaker": "Shopkeeper"},
						]},
				],
			},
			{"type": "house", "pos": Vector2i(-16, -6)},
			{"type": "house", "pos": Vector2i(-8, -6)},
			{"type": "house", "pos": Vector2i(4, -6)},
			{"type": "house", "pos": Vector2i(12, -6)},
			{"type": "house", "pos": Vector2i(-8, 8)},
		],
		"features": [
			{"type": "water", "pos": Vector2i(-20, 16), "size": Vector2i(8, 6)},
			{"type": "flowers", "pos": Vector2i(10, 16), "size": Vector2i(8, 5)},
			{"type": "fence", "pos": Vector2i(-20, 10), "size": Vector2i(6, 1)},
			{"type": "fence", "pos": Vector2i(14, 10), "size": Vector2i(6, 1)},
			{"type": "water", "pos": Vector2i(-2, 4), "size": Vector2i(4, 3)},
			{"type": "flowers", "pos": Vector2i(-20, 24), "size": Vector2i(4, 3)},
			{"type": "flowers", "pos": Vector2i(20, 6), "size": Vector2i(4, 4)},
		],
		"npcs": [
			{"pos": Vector2(-176, -176), "lines": ["This is the Monster Town Hospital.\nGo inside to heal!"], "bubble": "Hospital"},
			{"pos": Vector2(144, -176), "lines": ["This is the Monster Town Shop.\nGo inside to browse!"], "bubble": "Shop"},
			{
				"pos": Vector2(-48, -128),
				"lines": ["Welcome to Monster Town!", "Go explore and catch monsters!"],
				"bubble": "Hey there!",
				"dialogue": [
					{"id": "start", "text": "Welcome to Monster Town!", "speaker": "Elder", "choices": [
						{"label": "Tell me about quests", "next": "quests"},
						{"label": "Any tips?", "next": "tips"},
						{"label": "Goodbye", "next": "bye"},
					]},
					{"id": "quests", "text": "There's always work to be done!\nTalk to folks around town.", "speaker": "Elder"},
					{"id": "tips", "text": "Press Q for your quest log.\nPress M to view the world map!", "speaker": "Elder"},
					{"id": "bye", "text": "Good luck on your adventure!", "speaker": "Elder"},
				],
			},
			{"pos": Vector2(96, -32), "lines": ["I heard there are monsters\nin the tall grass nearby.", "Be careful out there!"], "bubble": "Monsters are scary..."},
			{"pos": Vector2(-96, 32), "lines": ["Press Tab to check your party.\nPress I to open inventory.", "Good luck on your adventure!"], "bubble": "Need some tips?"},
			{"pos": Vector2(224, -32), "lines": ["The hospital is to the north.\nIf your monsters faint,\ngo heal them!"], "bubble": "Hospital is north!"},
			{"pos": Vector2(-240, 32), "lines": ["I love sitting by the pond.\nIt's so peaceful here."], "bubble": "Nice day..."},
			{"pos": Vector2(48, 160), "lines": ["Have you seen the flowers?\nThey bloom every season!", "Monster Town is beautiful."], "bubble": "Pretty flowers!"},
			{"pos": Vector2(-128, 160), "lines": ["My grandpa says there used to be\nonly wild monsters here.\nNow we have a whole town!"], "bubble": "Did you know?"},
			{"pos": Vector2(192, 128), "lines": ["Hold LB or Shift to run faster!\nPress Y or Space to jump!", "And hold RT for 4x speed!"], "bubble": "Movement tips!"},
		],
		"pc_terminals": [],
		"transitions": [
			{"edge": "north", "target_area": "route1", "spawn_offset": Vector2(0, -32)},
		],
	},
	"route1": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 35,
		"tile_palette": "route",
		"pois": [
			{"type": "sign", "pos": Vector2(0, -300), "lines": ["Route 1", "Connecting Monster Town\nto the north."]},
			{"type": "rest_stop", "pos": Vector2(-160, 80)},
			{"type": "berry_tree", "pos": Vector2(200, 240)},
		],
		"npcs": [
			{"pos": Vector2(160, 160), "lines": ["This is Route 1!", "The monsters here are stronger."], "bubble": "Watch your step!"},
		],
		"trainers": [
			{
				"pos": Vector2(-80, -160),
				"trainer_id": "route1_trainer1",
				"name": "Youngster Joey",
				"monster_ids": [12, 20],
				"monster_levels": [6, 7],
				"dialogue_before": ["I just got my first monsters!\nLet's see who's stronger!"],
				"dialogue_after": ["Wow, you're really good!"],
			},
			{
				"pos": Vector2(80, 160),
				"trainer_id": "route1_trainer2",
				"name": "Lass Amy",
				"monster_ids": [21, 14],
				"monster_levels": [7, 8],
				"dialogue_before": ["My monsters are the cutest\nAND the strongest!"],
				"dialogue_after": ["Maybe I need to\ntrain more..."],
			},
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
			{"edge": "south", "target_area": "town", "spawn_offset": Vector2(0, 32)},
			{"edge": "north", "target_area": "route2", "spawn_offset": Vector2(0, -32)},
		],
	},
	"route2": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 40,
		"tile_palette": "route",
		"weather": "rain",
		"pois": [
			{"type": "sign", "pos": Vector2(0, -380), "lines": ["Route 2", "Rainy path to Coral City.\nWatch your footing!"]},
			{"type": "clearing", "pos": Vector2(-200, 160), "npc_lines": ["I found a rare potion\nhidden in the grass!", "Here, take this one."], "npc_bubble": "Lucky find!"},
			{"type": "rest_stop", "pos": Vector2(180, -100)},
		],
		"npcs": [
			{"pos": Vector2(200, 100), "lines": ["The gym leader in Coral City\nis really tough!"], "bubble": "A warning..."},
		],
		"trainers": [
			{
				"pos": Vector2(-96, -176),
				"trainer_id": "route2_trainer1",
				"name": "Bug Catcher Tim",
				"monster_ids": [7, 8],
				"monster_levels": [8, 9],
				"dialogue_before": ["Hey! Let's battle!"],
				"dialogue_after": ["You're strong!"],
			},
			{
				"pos": Vector2(64, 112),
				"trainer_id": "route2_trainer2",
				"name": "Picnicker Lily",
				"monster_ids": [20, 9],
				"monster_levels": [9, 10],
				"dialogue_before": ["I was just having a picnic\nwhen you walked by!"],
				"dialogue_after": ["Well, back to my\nsandwiches..."],
			},
		],
		"wild_monsters": [
			{"pos": Vector2(150, 50), "monster_id": 9, "level_min": 8, "level_max": 12},
			{"pos": Vector2(300, 180), "monster_id": 11, "level_min": 9, "level_max": 13},
			{"pos": Vector2(100, 280), "monster_id": 15, "level_min": 8, "level_max": 11},
			{"pos": Vector2(350, 50), "monster_id": 19, "level_min": 10, "level_max": 14},
			{"pos": Vector2(450, 300), "monster_id": 22, "level_min": 9, "level_max": 12},
			{"pos": Vector2(50, 400), "monster_id": 27, "level_min": 10, "level_max": 14},
		],
		"transitions": [
			{"edge": "south", "target_area": "route1", "spawn_offset": Vector2(0, 32)},
			{"edge": "north", "target_area": "town2", "spawn_offset": Vector2(0, -32)},
		],
	},
	"town2": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 42,
		"tile_palette": "town",
		"safe_zone": true,
		"buildings": [
			{"type": "hospital", "pos": Vector2i(-16, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Your monsters are fully healed!"], "bubble": "Need healing?",
						"dialogue": [
							{"id": "start", "text": "Welcome to the Coral City\nHospital! Want me to heal\nyour monsters?", "speaker": "Nurse", "choices": [
								{"label": "Yes, please", "next": "heal"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "heal", "text": "All better! Your monsters\nare fully healed.", "speaker": "Nurse", "action": "heal_party"},
							{"id": "bye", "text": "Take care out there!", "speaker": "Nurse"},
						]},
				],
				"interior_pc_terminals": [{"pos": Vector2(48, -32)}],
			},
			{"type": "shop", "pos": Vector2i(6, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Welcome to my shop!"], "bubble": "Buy something!",
						"dialogue": [
							{"id": "start", "text": "Welcome! Care to browse my wares?", "speaker": "Shopkeeper", "choices": [
								{"label": "Browse wares", "next": "shop"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "shop", "text": "Take a look!", "speaker": "Shopkeeper", "action": "open_shop"},
							{"id": "bye", "text": "Come back anytime!", "speaker": "Shopkeeper"},
						]},
				],
			},
			{"type": "gym", "pos": Vector2i(14, -6),
				"interior_trainers": [
					{
						"pos": Vector2(0, -64),
						"trainer_id": "town2_gym",
						"name": "Gym Leader Coral",
						"monster_ids": [5, 2],
						"monster_levels": [14, 12],
						"dialogue_before": ["I am Coral, master of Water-types!", "Prepare yourself!"],
						"dialogue_after": ["Impressive... You've earned\nthe Tide Badge!"],
						"is_gym_leader": true,
						"badge_id": "tide_badge",
						"sight_dir": "down",
					},
				],
			},
			{"type": "house", "pos": Vector2i(-16, -6)},
			{"type": "house", "pos": Vector2i(-8, -6)},
			{"type": "house", "pos": Vector2i(4, 8)},
			{"type": "house", "pos": Vector2i(-12, 8)},
		],
		"features": [
			{"type": "water", "pos": Vector2i(-20, 22), "size": Vector2i(40, 8)},
			{"type": "fence", "pos": Vector2i(-20, 20), "size": Vector2i(40, 2)},
			{"type": "flowers", "pos": Vector2i(-18, 14), "size": Vector2i(6, 4)},
			{"type": "flowers", "pos": Vector2i(14, 14), "size": Vector2i(6, 4)},
		],
		"npcs": [
			{"pos": Vector2(-208, -176), "lines": ["This is the Coral City Hospital.\nGo inside to heal!"], "bubble": "Hospital"},
			{"pos": Vector2(144, -176), "lines": ["This is the Coral City Shop.\nGo inside to browse!"], "bubble": "Shop"},
			{"pos": Vector2(-48, -128), "lines": ["Welcome to Coral City!", "Our gym leader specializes\nin Water-types."], "bubble": "Welcome!"},
			{"pos": Vector2(96, 96), "lines": ["The gym is in the northeast.\nGo inside to challenge the leader!"], "bubble": "Good luck!"},
			{"pos": Vector2(-160, 64), "lines": ["The harbor down south connects\nus to distant lands.\nSailors bring rare items!"], "bubble": "The harbor..."},
			{"pos": Vector2(48, 160), "lines": ["I love the sound of the waves.\nCoral City is the best place\nto raise Water-types!"], "bubble": "Ocean breeze..."},
			{"pos": Vector2(-96, 160), "lines": ["Did you know? The Tide Badge\nlets your monsters use Surf\noutside of battle!"], "bubble": "Badge info!"},
			{"pos": Vector2(208, 96), "lines": ["I'm training to be a fisherman.\nThe waters here are full of\namazing monsters!"], "bubble": "Fishing tales..."},
		],
		"pc_terminals": [],
		"trainers": [],
		"transitions": [
			{"edge": "south", "target_area": "route2", "spawn_offset": Vector2(0, 32)},
			{"edge": "east", "target_area": "route3", "spawn_offset": Vector2(-32, 0)},
		],
	},
	"route3": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 42,
		"tile_palette": "route",
		"pois": [
			{"type": "sign", "pos": Vector2(-400, 0), "lines": ["Route 3", "Mountain pass between\nCoral City and Ember Ridge."]},
			{"type": "clearing", "pos": Vector2(200, -180), "npc_lines": ["The mountain air is great\nfor training Fire-types!"], "npc_bubble": "Training spot!"},
			{"type": "berry_tree", "pos": Vector2(-240, 200)},
			{"type": "rest_stop", "pos": Vector2(100, 120)},
		],
		"trainers": [
			{
				"pos": Vector2(-240, -96),
				"trainer_id": "route3_trainer1",
				"name": "Hiker Brock",
				"monster_ids": [10, 13],
				"monster_levels": [14, 15],
				"dialogue_before": ["These mountains are\nmy training grounds!"],
				"dialogue_after": ["Your strength is\nlike a landslide!"],
			},
			{
				"pos": Vector2(160, 96),
				"trainer_id": "route3_trainer2",
				"name": "Fire Breather Kai",
				"monster_ids": [4, 6],
				"monster_levels": [13, 16],
				"dialogue_before": ["Feel the heat\nof my flames!"],
				"dialogue_after": ["I've been\nextinguished..."],
			},
			{
				"pos": Vector2(0, 0),
				"trainer_id": "route3_trainer3",
				"name": "Ace Trainer Sora",
				"monster_ids": [11, 7],
				"monster_levels": [15, 16],
				"dialogue_before": ["An Ace Trainer never\nbacks down from a fight!"],
				"dialogue_after": ["You've got real\npotential!"],
			},
		],
		"wild_monsters": [
			{"pos": Vector2(100, 80), "monster_id": 4, "level_min": 12, "level_max": 16},
			{"pos": Vector2(300, 60), "monster_id": 10, "level_min": 13, "level_max": 17},
			{"pos": Vector2(50, 250), "monster_id": 13, "level_min": 12, "level_max": 15},
			{"pos": Vector2(250, 200), "monster_id": 16, "level_min": 14, "level_max": 18},
			{"pos": Vector2(400, 150), "monster_id": 23, "level_min": 13, "level_max": 16},
			{"pos": Vector2(180, 350), "monster_id": 26, "level_min": 14, "level_max": 17},
			{"pos": Vector2(350, 300), "monster_id": 29, "level_min": 15, "level_max": 18},
		],
		"transitions": [
			{"edge": "west", "target_area": "town2", "spawn_offset": Vector2(32, 0)},
			{"edge": "east", "target_area": "town3", "spawn_offset": Vector2(-32, 0)},
		],
	},
	"town3": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 44,
		"tile_palette": "town",
		"safe_zone": true,
		"buildings": [
			{"type": "hospital", "pos": Vector2i(6, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Rest here and heal your monsters!"], "bubble": "Need healing?",
						"dialogue": [
							{"id": "start", "text": "You look tired! Want me to\nheal your monsters?", "speaker": "Nurse", "choices": [
								{"label": "Yes, please", "next": "heal"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "heal", "text": "All better! Your monsters\nare fully healed.", "speaker": "Nurse", "action": "heal_party"},
							{"id": "bye", "text": "Take care out there!", "speaker": "Nurse"},
						]},
				],
				"interior_pc_terminals": [{"pos": Vector2(48, -32)}],
			},
			{"type": "shop", "pos": Vector2i(-14, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Welcome to my shop!"], "bubble": "Buy something!",
						"dialogue": [
							{"id": "start", "text": "Welcome! Care to browse my wares?", "speaker": "Shopkeeper", "choices": [
								{"label": "Browse wares", "next": "shop"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "shop", "text": "Take a look!", "speaker": "Shopkeeper", "action": "open_shop"},
							{"id": "bye", "text": "Come back anytime!", "speaker": "Shopkeeper"},
						]},
				],
			},
			{"type": "house", "pos": Vector2i(-16, -6)},
			{"type": "house", "pos": Vector2i(-8, -6)},
			{"type": "house", "pos": Vector2i(4, -6)},
			{"type": "house", "pos": Vector2i(12, -6)},
			{"type": "house", "pos": Vector2i(-12, 8)},
			{"type": "house", "pos": Vector2i(4, 8)},
		],
		"features": [
			{"type": "water", "pos": Vector2i(-20, 18), "size": Vector2i(6, 4)},
			{"type": "flowers", "pos": Vector2i(16, 18), "size": Vector2i(6, 4)},
			{"type": "fence", "pos": Vector2i(-22, 14), "size": Vector2i(10, 1)},
			{"type": "fence", "pos": Vector2i(14, 14), "size": Vector2i(10, 1)},
			{"type": "flowers", "pos": Vector2i(-4, 18), "size": Vector2i(8, 3)},
		],
		"npcs": [
			{"pos": Vector2(144, -176), "lines": ["This is the Ember Ridge Hospital.\nGo inside to heal!"], "bubble": "Hospital"},
			{"pos": Vector2(-176, -176), "lines": ["This is the Ember Ridge Shop.\nGo inside to browse!"], "bubble": "Shop"},
			{
				"pos": Vector2(-48, -128),
				"lines": ["Welcome to Ember Ridge!"],
				"bubble": "Greetings!",
				"dialogue": [
					{"id": "start", "text": "I'm the mayor of Ember Ridge.\nThis town was built near\nan ancient volcano.", "speaker": "Mayor", "choices": [
						{"label": "Tell me more", "next": "info"},
						{"label": "Any quests?", "next": "quest"},
						{"label": "Goodbye", "next": "bye"},
					]},
					{"id": "info", "text": "Fire-type monsters roam\nthe routes nearby.\nBe prepared!", "speaker": "Mayor"},
					{"id": "quest", "text": "Explore Route 3 and defeat\nthe trainers there.\nProve your strength!", "speaker": "Mayor"},
					{"id": "bye", "text": "Good luck, adventurer!", "speaker": "Mayor"},
				],
			},
			{"pos": Vector2(96, -32), "lines": ["Fire-type monsters are strong\nagainst Grass but weak to Water.", "Keep a Water-type handy!"], "bubble": "Fire types..."},
			{"pos": Vector2(-240, 32), "lines": ["The volcano hasn't erupted\nin centuries, but you can still\nfeel the heat underground."], "bubble": "Warm ground..."},
			{"pos": Vector2(208, 32), "lines": ["The blacksmith in town forges\nthe strongest gear. His fire\nmonsters help with the smelting!"], "bubble": "Blacksmith tales..."},
			{"pos": Vector2(-128, 160), "lines": ["I train my monsters near the\nlava pools. The heat makes\nthem stronger!"], "bubble": "Training hard!"},
			{"pos": Vector2(96, 160), "lines": ["Ember Ridge was founded by\nfire tamers. Our ancestors\nbefriended Fire-type monsters."], "bubble": "Town history..."},
		],
		"pc_terminals": [],
		"transitions": [
			{"edge": "west", "target_area": "route3", "spawn_offset": Vector2(32, 0)},
			{"edge": "south", "target_area": "route4", "spawn_offset": Vector2(0, -32)},
		],
	},
	"route4": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 44,
		"tile_palette": "route",
		"weather": "fog",
		"pois": [
			{"type": "sign", "pos": Vector2(0, -420), "lines": ["Route 4", "Fog-shrouded path.\nExplore carefully!"]},
			{"type": "clearing", "pos": Vector2(-220, -120), "npc_lines": ["I got lost in the fog\nand found this clearing.\nThere might be treasure nearby!"], "npc_bubble": "Lost traveler..."},
			{"type": "clearing", "pos": Vector2(180, 200), "npc_lines": ["The fog hides many secrets.\nKeep searching!"], "npc_bubble": "Mysterious..."},
			{"type": "rest_stop", "pos": Vector2(-100, 160)},
		],
		"trainers": [
			{
				"pos": Vector2(-96, -176),
				"trainer_id": "route4_trainer1",
				"name": "Ranger Thorne",
				"monster_ids": [6, 8],
				"monster_levels": [20, 21],
				"dialogue_before": ["The fog hides many\ndangers on this path!"],
				"dialogue_after": ["You navigate well\nthrough the mist..."],
			},
			{
				"pos": Vector2(96, 128),
				"trainer_id": "route4_trainer2",
				"name": "Mystic Elara",
				"monster_ids": [12, 28],
				"monster_levels": [22, 22],
				"dialogue_before": ["The fog whispers\nof your arrival..."],
				"dialogue_after": ["Your light pierces\neven this gloom."],
			},
			{
				"pos": Vector2(0, -32),
				"trainer_id": "route4_trainer3",
				"name": "Hex Maniac Raven",
				"monster_ids": [11, 24],
				"monster_levels": [21, 22],
				"dialogue_before": ["The darkness speaks\nto me... and it says\nyou will lose!"],
				"dialogue_after": ["The shadows retreat\nbefore your light..."],
			},
		],
		"wild_monsters": [
			{"pos": Vector2(120, 60), "monster_id": 1, "level_min": 18, "level_max": 22},
			{"pos": Vector2(320, 100), "monster_id": 28, "level_min": 20, "level_max": 24},
			{"pos": Vector2(80, 260), "monster_id": 8, "level_min": 19, "level_max": 23},
			{"pos": Vector2(280, 220), "monster_id": 12, "level_min": 18, "level_max": 22},
			{"pos": Vector2(450, 180), "monster_id": 3, "level_min": 20, "level_max": 24},
			{"pos": Vector2(180, 380), "monster_id": 2, "level_min": 19, "level_max": 23},
		],
		"transitions": [
			{"edge": "north", "target_area": "town3", "spawn_offset": Vector2(0, 32)},
			{"edge": "south", "target_area": "town4", "spawn_offset": Vector2(0, -32)},
		],
	},
	"town4": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 44,
		"tile_palette": "town",
		"safe_zone": true,
		"buildings": [
			{"type": "hospital", "pos": Vector2i(6, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Rest here and heal your monsters!"], "bubble": "Need healing?",
						"dialogue": [
							{"id": "start", "text": "You look tired! Want me to\nheal your monsters?", "speaker": "Nurse", "choices": [
								{"label": "Yes, please", "next": "heal"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "heal", "text": "All better! Your monsters\nare fully healed.", "speaker": "Nurse", "action": "heal_party"},
							{"id": "bye", "text": "Take care out there!", "speaker": "Nurse"},
						]},
				],
				"interior_pc_terminals": [{"pos": Vector2(48, -32)}],
			},
			{"type": "shop", "pos": Vector2i(-14, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Welcome to my shop!"], "bubble": "Buy something!",
						"dialogue": [
							{"id": "start", "text": "Welcome! Care to browse my wares?", "speaker": "Shopkeeper", "choices": [
								{"label": "Browse wares", "next": "shop"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "shop", "text": "Take a look!", "speaker": "Shopkeeper", "action": "open_shop"},
							{"id": "bye", "text": "Come back anytime!", "speaker": "Shopkeeper"},
						]},
				],
			},
			{"type": "gym", "pos": Vector2i(-16, -6),
				"interior_trainers": [
					{
						"pos": Vector2(0, -64),
						"trainer_id": "town4_gym",
						"name": "Gym Leader Ivy",
						"monster_ids": [6, 3],
						"monster_levels": [24, 22],
						"dialogue_before": ["I am Ivy, guardian of the grove!", "Nature's strength flows through me!"],
						"dialogue_after": ["You've proven your worth...\nTake the Grove Badge!"],
						"is_gym_leader": true,
						"badge_id": "grove_badge",
						"sight_dir": "down",
					},
				],
			},
			{"type": "house", "pos": Vector2i(-8, -6)},
			{"type": "house", "pos": Vector2i(4, -6)},
			{"type": "house", "pos": Vector2i(12, -6)},
			{"type": "house", "pos": Vector2i(-12, 8)},
			{"type": "house", "pos": Vector2i(4, 8)},
			{"type": "house", "pos": Vector2i(14, 8)},
		],
		"features": [
			{"type": "flowers", "pos": Vector2i(-22, 16), "size": Vector2i(10, 6)},
			{"type": "fence", "pos": Vector2i(-22, 15), "size": Vector2i(10, 1)},
			{"type": "fence", "pos": Vector2i(-22, 22), "size": Vector2i(10, 1)},
			{"type": "trees", "pos": Vector2i(14, 16), "size": Vector2i(8, 6)},
			{"type": "flowers", "pos": Vector2i(-4, 20), "size": Vector2i(8, 4)},
			{"type": "flowers", "pos": Vector2i(6, 4), "size": Vector2i(4, 3)},
		],
		"npcs": [
			{"pos": Vector2(144, -176), "lines": ["This is the Verdant Grove Hospital.\nGo inside to heal!"], "bubble": "Hospital"},
			{"pos": Vector2(-176, -176), "lines": ["This is the Verdant Grove Shop.\nGo inside to browse!"], "bubble": "Shop"},
			{
				"pos": Vector2(-48, -128),
				"lines": ["Welcome to Verdant Grove!"],
				"bubble": "Greetings!",
				"dialogue": [
					{"id": "start", "text": "I am the elder of Verdant Grove.\nOur town thrives among\nthe ancient trees.", "speaker": "Elder", "choices": [
						{"label": "Tell me more", "next": "info"},
						{"label": "Any quests?", "next": "quest"},
						{"label": "Goodbye", "next": "bye"},
					]},
					{"id": "info", "text": "Grass-type monsters flourish here.\nThe gym leader Ivy draws\nstrength from nature itself.", "speaker": "Elder"},
					{"id": "quest", "text": "Help us clear the foggy route\nto the north. Defeat the\ntrainers lurking there!", "speaker": "Elder"},
					{"id": "bye", "text": "May the forest guide you.", "speaker": "Elder"},
				],
			},
			{"pos": Vector2(96, -32), "lines": ["Grass-types resist Water and\nElectric, but watch out for\nFire and Ice!", "Ivy's team is no pushover!"], "bubble": "Grass tips..."},
			{"pos": Vector2(-240, 32), "lines": ["The greenhouse is my pride!\nI grow rare berries that\ncan heal any ailment."], "bubble": "Greenhouse..."},
			{"pos": Vector2(208, 32), "lines": ["The ancient trees here are\nover a thousand years old.\nThey protect the grove."], "bubble": "Ancient trees..."},
			{"pos": Vector2(-128, 160), "lines": ["I practice my gardening\nevery day. Grass-type monsters\nhelp the flowers grow!"], "bubble": "Garden lover..."},
			{"pos": Vector2(96, 160), "lines": ["The maze garden to the south\nis a great place to train.\nWatch out for wild monsters!"], "bubble": "Garden maze..."},
		],
		"pc_terminals": [],
		"trainers": [],
		"transitions": [
			{"edge": "north", "target_area": "route4", "spawn_offset": Vector2(0, 32)},
			{"edge": "south", "target_area": "route5", "spawn_offset": Vector2(0, -32)},
		],
	},
	"route5": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 46,
		"tile_palette": "route",
		"weather": "sandstorm",
		"pois": [
			{"type": "sign", "pos": Vector2(0, -440), "lines": ["Route 5", "Final stretch to Stormhaven.\nBrace for sandstorms!"]},
			{"type": "clearing", "pos": Vector2(220, -160), "npc_lines": ["They say the strongest trainers\nwait at the end of this route.\nPrepare yourself!"], "npc_bubble": "A warning..."},
			{"type": "berry_tree", "pos": Vector2(-200, 100)},
			{"type": "rest_stop", "pos": Vector2(140, 260)},
		],
		"trainers": [
			{
				"pos": Vector2(-112, -192),
				"trainer_id": "route5_trainer1",
				"name": "Storm Chaser Nova",
				"monster_ids": [7, 8],
				"monster_levels": [24, 25],
				"dialogue_before": ["This sandstorm fuels\nmy fighting spirit!"],
				"dialogue_after": ["The storm couldn't\nstop you either!"],
			},
			{
				"pos": Vector2(112, 144),
				"trainer_id": "route5_trainer2",
				"name": "Veteran Marcus",
				"monster_ids": [28, 12],
				"monster_levels": [26, 26],
				"dialogue_before": ["I've trained in these\nwastelands for years!"],
				"dialogue_after": ["A worthy opponent\nat last..."],
			},
			{
				"pos": Vector2(0, -48),
				"trainer_id": "route5_trainer3",
				"name": "Blackbelt Feng",
				"monster_ids": [13, 30],
				"monster_levels": [25, 26],
				"dialogue_before": ["My fists are harder\nthan steel! Prepare\nyourself!"],
				"dialogue_after": ["Your spirit is\nunbreakable..."],
			},
		],
		"wild_monsters": [
			{"pos": Vector2(130, 70), "monster_id": 28, "level_min": 22, "level_max": 26},
			{"pos": Vector2(340, 60), "monster_id": 1, "level_min": 23, "level_max": 27},
			{"pos": Vector2(60, 250), "monster_id": 7, "level_min": 22, "level_max": 26},
			{"pos": Vector2(280, 200), "monster_id": 8, "level_min": 24, "level_max": 28},
			{"pos": Vector2(420, 160), "monster_id": 12, "level_min": 23, "level_max": 27},
			{"pos": Vector2(190, 360), "monster_id": 5, "level_min": 24, "level_max": 28},
			{"pos": Vector2(370, 310), "monster_id": 6, "level_min": 22, "level_max": 26},
		],
		"transitions": [
			{"edge": "north", "target_area": "town4", "spawn_offset": Vector2(0, 32)},
			{"edge": "south", "target_area": "town5", "spawn_offset": Vector2(0, -32)},
		],
	},
	"town5": {
		"music": "res://assets/audio/music/town_theme.wav",
		"map_size": 44,
		"tile_palette": "town",
		"safe_zone": true,
		"buildings": [
			{"type": "hospital", "pos": Vector2i(6, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Rest here and heal your monsters!"], "bubble": "Need healing?",
						"dialogue": [
							{"id": "start", "text": "You look tired! Want me to\nheal your monsters?", "speaker": "Nurse", "choices": [
								{"label": "Yes, please", "next": "heal"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "heal", "text": "All better! Your monsters\nare fully healed.", "speaker": "Nurse", "action": "heal_party"},
							{"id": "bye", "text": "Take care out there!", "speaker": "Nurse"},
						]},
				],
				"interior_pc_terminals": [{"pos": Vector2(48, -32)}],
			},
			{"type": "shop", "pos": Vector2i(-14, -16),
				"interior_npcs": [
					{"pos": Vector2(0, -48), "lines": ["Welcome to my shop!"], "bubble": "Buy something!",
						"dialogue": [
							{"id": "start", "text": "Welcome! Care to browse my wares?", "speaker": "Shopkeeper", "choices": [
								{"label": "Browse wares", "next": "shop"},
								{"label": "No thanks", "next": "bye"},
							]},
							{"id": "shop", "text": "Take a look!", "speaker": "Shopkeeper", "action": "open_shop"},
							{"id": "bye", "text": "Come back anytime!", "speaker": "Shopkeeper"},
						]},
				],
			},
			{"type": "gym", "pos": Vector2i(-16, -6),
				"interior_trainers": [
					{
						"pos": Vector2(0, -64),
						"trainer_id": "town5_gym",
						"name": "Gym Leader Volt",
						"monster_ids": [27, 7],
						"monster_levels": [28, 26],
						"dialogue_before": ["I am Volt, master of lightning!", "Feel the surge of electricity!"],
						"dialogue_after": ["Shocking... You've earned\nthe Storm Badge!"],
						"is_gym_leader": true,
						"badge_id": "storm_badge",
						"sight_dir": "down",
					},
				],
			},
			{"type": "house", "pos": Vector2i(-8, -6)},
			{"type": "house", "pos": Vector2i(4, -6)},
			{"type": "house", "pos": Vector2i(12, -6)},
			{"type": "house", "pos": Vector2i(-12, 8)},
			{"type": "house", "pos": Vector2i(4, 8)},
			{"type": "house", "pos": Vector2i(14, 8)},
		],
		"features": [
			{"type": "fence", "pos": Vector2i(-22, 16), "size": Vector2i(6, 6)},
			{"type": "fence", "pos": Vector2i(18, 16), "size": Vector2i(6, 6)},
			{"type": "water", "pos": Vector2i(-4, 18), "size": Vector2i(8, 4)},
			{"type": "flowers", "pos": Vector2i(-18, 24), "size": Vector2i(6, 3)},
			{"type": "flowers", "pos": Vector2i(14, 24), "size": Vector2i(6, 3)},
		],
		"npcs": [
			{"pos": Vector2(144, -176), "lines": ["This is the Stormhaven Hospital.\nGo inside to heal!"], "bubble": "Hospital"},
			{"pos": Vector2(-176, -176), "lines": ["This is the Stormhaven Shop.\nGo inside to browse!"], "bubble": "Shop"},
			{
				"pos": Vector2(-48, -128),
				"lines": ["Welcome to Stormhaven!"],
				"bubble": "Greetings!",
				"dialogue": [
					{"id": "start", "text": "I'm the mayor of Stormhaven.\nOur town was built to weather\nany storm.", "speaker": "Mayor", "choices": [
						{"label": "Tell me more", "next": "info"},
						{"label": "Any quests?", "next": "quest"},
						{"label": "Goodbye", "next": "bye"},
					]},
					{"id": "info", "text": "Electric-type monsters are drawn\nto the storms that rage nearby.\nGym Leader Volt harnesses\nthat power.", "speaker": "Mayor"},
					{"id": "quest", "text": "Brave the sandstorm on Route 5\nand prove you belong here!", "speaker": "Mayor"},
					{"id": "bye", "text": "Stay safe, traveler!", "speaker": "Mayor"},
				],
			},
			{"pos": Vector2(96, -32), "lines": ["Electric-types are fast and\nhit hard! Ground-types are\nimmune to their attacks.", "Bring a Ground-type to\nthe gym!"], "bubble": "Electric tips..."},
			{"pos": Vector2(-240, 32), "lines": ["The lightning rod tower keeps\nour town safe from strikes.\nIt was built by the first\ngym leader!"], "bubble": "Lightning rod..."},
			{"pos": Vector2(208, 32), "lines": ["During storms, you can see\nElectric-type monsters dancing\nin the lightning!"], "bubble": "Storm watching..."},
			{"pos": Vector2(-128, 160), "lines": ["The storm shelter underground\ncan hold the whole town.\nWe've weathered many storms!"], "bubble": "Storm shelter..."},
			{"pos": Vector2(96, 160), "lines": ["I work at the power station.\nWe harness storm energy to\npower all of Stormhaven!"], "bubble": "Power station..."},
		],
		"pc_terminals": [],
		"trainers": [],
		"transitions": [
			{"edge": "north", "target_area": "route5", "spawn_offset": Vector2(0, 32)},
		],
	},
}

# ── Interior Templates ──
const INTERIOR_TEMPLATES: Dictionary = {
	"hospital": {"interior_size": Vector2i(16, 10), "map_size": 10},
	"shop": {"interior_size": Vector2i(16, 10), "map_size": 10},
	"gym": {"interior_size": Vector2i(20, 14), "map_size": 14},
	"house": {"interior_size": Vector2i(10, 8), "map_size": 8},
}

func _ready() -> void:
	var area_config: Dictionary = _get_area_config()
	_setup_tilemap(area_config)

	if GameManager.is_in_building:
		_spawn_interior_exit(area_config)
		_spawn_npcs(area_config)
		_spawn_trainers(area_config)
		_spawn_pc_terminals(area_config)
		_update_player_sprite()
		_restore_player_position()
		# Hide follower indoors (small rooms cause wall clipping)
		if follower:
			follower.visible = false
		_show_area_name()
		# No day/night or weather indoors
		AudioManager.play_music(area_config["music"], false)
		# Constrain camera to interior bounds
		_setup_interior_camera(area_config)
		if hint_bar:
			hint_bar.set_hints([
				{"icon": "lstick", "label": "Move"},
				{"icon": "btn_a", "label": "Interact"},
				{"icon": "btn_b", "label": "Exit"},
				{"icon": "btn_start", "label": "Party"},
			])
	else:
		_spawn_npcs(area_config)
		_spawn_trainers(area_config)
		_spawn_pc_terminals(area_config)
		_spawn_wild_monsters(area_config)
		_spawn_pois(area_config)
		_spawn_transition_zones(area_config)
		_spawn_building_doors(area_config)
		_update_player_sprite()
		_restore_player_position()
		_setup_follower()
		_show_area_name()
		_setup_day_night()
		_setup_weather(area_config)
		AudioManager.play_music(area_config["music"], false)
		if hint_bar:
			hint_bar.set_hints([
				{"icon": "lstick", "label": "Move"},
				{"icon": "btn_b", "label": "Run"},
				{"icon": "btn_y", "label": "Jump"},
				{"icon": "btn_x", "label": "Attack"},
				{"icon": "btn_a", "label": "Interact"},
				{"icon": "btn_start", "label": "Party"},
			])
	if _auto_test:
		_run_auto_test()

func _get_area_config() -> Dictionary:
	var area: String = GameManager.current_area
	if AREA_DATA.has(area):
		return AREA_DATA[area]
	if area.find("_interior_") != -1:
		return _build_interior_config(area)
	return AREA_DATA["town"]

func _build_interior_config(area_key: String) -> Dictionary:
	# Format: "{parent}_interior_{type}_{index}"
	var parts: PackedStringArray = area_key.split("_interior_")
	if parts.size() < 2:
		return AREA_DATA["town"]
	var parent_area: String = parts[0]
	var suffix: String = parts[1]  # e.g. "hospital_0" or "shop_1"
	var suffix_parts: PackedStringArray = suffix.rsplit("_", true, 1)
	var btype: String = suffix_parts[0]
	var bindex: int = int(suffix_parts[1]) if suffix_parts.size() > 1 else 0

	var parent_config: Dictionary = AREA_DATA.get(parent_area, {})
	var buildings: Array = parent_config.get("buildings", [])
	var building: Dictionary = buildings[bindex] if bindex < buildings.size() else {}

	var template: Dictionary = INTERIOR_TEMPLATES.get(btype, INTERIOR_TEMPLATES["house"])
	var interior_size: Vector2i = template["interior_size"]

	# Build area name for display
	var area_names: Dictionary = {
		"town": "Monster Town", "town2": "Coral City", "town3": "Ember Ridge",
		"town4": "Verdant Grove", "town5": "Stormhaven",
	}
	var town_name: String = area_names.get(parent_area, parent_area)
	var type_names: Dictionary = {
		"hospital": "Hospital", "shop": "Shop", "gym": "Gym", "house": "House",
	}
	var display_name: String = "%s %s" % [town_name, type_names.get(btype, "Building")]

	var config: Dictionary = {
		"music": parent_config.get("music", "res://assets/audio/music/town_theme.wav"),
		"map_size": template["map_size"],
		"tile_palette": "interior",
		"safe_zone": true,
		"interior_size": interior_size,
		"interior_type": btype,
		"interior_display_name": display_name,
		"parent_area": parent_area,
		"building_index": bindex,
		"npcs": building.get("interior_npcs", []),
		"trainers": building.get("interior_trainers", []),
		"pc_terminals": building.get("interior_pc_terminals", []),
	}
	return config

func _restore_player_position() -> void:
	var saved_pos: Variant = GameManager.get_area_player_position(GameManager.current_area)
	if saved_pos != null:
		player.position = saved_pos as Vector2

func _setup_follower() -> void:
	if follower and follower.has_method("setup"):
		follower.setup(player)

func _setup_tilemap(area_config: Dictionary) -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 2)

	var palette: String = area_config.get("tile_palette", "town")
	var map_size: int = area_config.get("map_size", 30)

	if palette == "town":
		_setup_town_tilemap(tile_set, map_size)
	elif palette == "interior":
		_setup_interior_tilemap(tile_set, area_config)
	else:
		_setup_route_tilemap(tile_set, map_size)

	tile_map.tile_set = tile_set

func _default_building_size(btype: String) -> Vector2i:
	match btype:
		"hospital": return Vector2i(6, 5)
		"shop": return Vector2i(6, 5)
		"gym": return Vector2i(5, 4)
		_: return Vector2i(4, 4)

func _setup_town_tilemap(tile_set: TileSet, map_size: int) -> void:
	var source := TileSetAtlasSource.new()
	var tex := AssetRegistry.load_texture(AssetRegistry.tileset_town)
	if not tex:
		tex = AssetRegistry.load_texture(AssetRegistry.tileset_route)
	if tex:
		source.texture = tex
		source.texture_region_size = Vector2i(16, 16)
		for i in 8:
			source.create_tile(Vector2i(i, 0))
		tile_set.add_source(source, 0)

	tile_map.tile_set = tile_set

	# Tile indices: 0=grass, 1=path, 2=water, 3=tree, 4=house_wall, 5=house_roof, 6=fence, 7=flowers
	var GRASS := Vector2i(0, 0)
	var PATH := Vector2i(1, 0)
	var WATER := Vector2i(2, 0)
	var TREE := Vector2i(3, 0)
	var WALL := Vector2i(4, 0)
	var ROOF := Vector2i(5, 0)
	var FENCE := Vector2i(6, 0)
	var FLOWERS := Vector2i(7, 0)

	# 1. Fill with grass
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			tile_map.set_cell(Vector2i(x, y), 0, GRASS)

	# 2. Tree border with transition openings
	var area_config: Dictionary = _get_area_config()
	var transitions: Array = area_config.get("transitions", [])
	var open_edges: Array = []
	for t in transitions:
		open_edges.append(t["edge"])

	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			if abs(x) >= map_size - 2 or abs(y) >= map_size - 2:
				var is_opening := false
				if "north" in open_edges and y <= -(map_size - 2) and abs(x) < 3:
					is_opening = true
				if "south" in open_edges and y >= map_size - 2 and abs(x) < 3:
					is_opening = true
				if "east" in open_edges and x >= map_size - 2 and abs(y) < 3:
					is_opening = true
				if "west" in open_edges and x <= -(map_size - 2) and abs(y) < 3:
					is_opening = true
				if is_opening:
					tile_map.set_cell(Vector2i(x, y), 0, PATH)
				else:
					tile_map.set_cell(Vector2i(x, y), 0, TREE)

	# 3. Render buildings from AREA_DATA
	var buildings: Array = area_config.get("buildings", [])
	var door_positions: Array = []

	for bldg in buildings:
		var bpos: Vector2i = bldg["pos"]
		var btype: String = bldg.get("type", "house")
		var bsize: Vector2i = bldg.get("size", _default_building_size(btype))
		var roof_h: int = maxi(1, bsize.y / 2)

		# Roof rows
		for x in range(bpos.x, bpos.x + bsize.x):
			for y in range(bpos.y, bpos.y + roof_h):
				tile_map.set_cell(Vector2i(x, y), 0, ROOF)
		# Wall rows
		for x in range(bpos.x, bpos.x + bsize.x):
			for y in range(bpos.y + roof_h, bpos.y + bsize.y):
				tile_map.set_cell(Vector2i(x, y), 0, WALL)

		# Door: bottom-center, one tile below building
		var door_x: int = bpos.x + bsize.x / 2
		var door_y: int = bpos.y + bsize.y
		door_positions.append(Vector2i(door_x, door_y))

		# Hospital marker: flower tile on roof center
		if btype == "hospital":
			tile_map.set_cell(Vector2i(bpos.x + bsize.x / 2, bpos.y + roof_h / 2), 0, FLOWERS)

	# 4. Path network
	# Main vertical spine (3 tiles wide)
	for y in range(-map_size + 2, map_size - 2):
		for dx in range(-1, 2):
			tile_map.set_cell(Vector2i(dx, y), 0, PATH)

	# Horizontal crossroad through center (2 tiles tall)
	var cross_extent: int = map_size - 4
	for x in range(-cross_extent, cross_extent + 1):
		tile_map.set_cell(Vector2i(x, 0), 0, PATH)
		tile_map.set_cell(Vector2i(x, 1), 0, PATH)

	# Connect each building door to the spine via horizontal branch
	for door in door_positions:
		var start_x: int = mini(door.x, -1)
		var end_x: int = maxi(door.x, 1)
		for x in range(start_x, end_x + 1):
			tile_map.set_cell(Vector2i(x, door.y), 0, PATH)
			tile_map.set_cell(Vector2i(x, door.y + 1), 0, PATH)
		# Vertical path from door branch to spine if far from crossroad
		if abs(door.y) > 2:
			var vy_start: int = mini(door.y, 0)
			var vy_end: int = maxi(door.y + 1, 1)
			for vy in range(vy_start, vy_end + 1):
				tile_map.set_cell(Vector2i(door.x, vy), 0, PATH)
				tile_map.set_cell(Vector2i(door.x + 1, vy), 0, PATH)

	# 5. Features (water, flowers, fence decorations)
	var features: Array = area_config.get("features", [])
	for feat in features:
		var fpos: Vector2i = feat["pos"]
		var fsize: Vector2i = feat.get("size", Vector2i(4, 4))
		var ftype: String = feat.get("type", "flowers")
		var tile: Vector2i
		match ftype:
			"water", "pond", "fountain": tile = WATER
			"flowers", "garden": tile = FLOWERS
			"fence": tile = FENCE
			"trees": tile = TREE
			_: tile = FLOWERS
		for x in range(fpos.x, fpos.x + fsize.x):
			for y in range(fpos.y, fpos.y + fsize.y):
				tile_map.set_cell(Vector2i(x, y), 0, tile)

	# 6. Collision on solid tiles
	_add_tile_collision(source, TREE)
	_add_tile_collision(source, WATER)
	_add_tile_collision(source, WALL)
	_add_tile_collision(source, ROOF)
	_add_tile_collision(source, FENCE)

	tile_map.modulate = Color(1.0, 1.0, 1.0)

func _compute_route_layout(map_size: int) -> Dictionary:
	var area_config: Dictionary = _get_area_config()
	var transitions: Array = area_config.get("transitions", [])
	var open_edges: Array = []
	for t in transitions:
		open_edges.append(t["edge"])

	# Route 3 is horizontal (east/west transitions), others are vertical
	var is_horizontal: bool = "east" in open_edges and "west" in open_edges and "north" not in open_edges and "south" not in open_edges

	var inner: int = map_size - 3
	var half_bend: int = map_size / 6
	var path_centers: Dictionary = {}  # primary_axis_coord -> cross_axis_center

	if is_horizontal:
		# Horizontal S-curve: X is primary axis, Y is cross axis
		for xi in range(-inner, inner + 1):
			var span: float = float(2 * inner)
			if span == 0.0:
				path_centers[xi] = 0
				continue
			var t: float = float(xi + inner) / span
			var cy: int = 0
			if t < 0.12:
				var local_t: float = t / 0.12
				cy = int(lerpf(0.0, float(-half_bend), local_t))
			elif t < 0.35:
				cy = -half_bend
			elif t < 0.65:
				var local_t: float = (t - 0.35) / 0.3
				cy = int(lerpf(float(-half_bend), float(half_bend), local_t))
			elif t < 0.88:
				cy = half_bend
			else:
				var local_t: float = (t - 0.88) / 0.12
				cy = int(lerpf(float(half_bend), 0.0, local_t))
			path_centers[xi] = cy
	else:
		# Vertical S-curve: Y is primary axis, X is cross axis
		for yi in range(-inner, inner + 1):
			var span: float = float(2 * inner)
			if span == 0.0:
				path_centers[yi] = 0
				continue
			var t: float = float(yi + inner) / span
			var cx: int = 0
			if t < 0.12:
				var local_t: float = t / 0.12
				cx = int(lerpf(0.0, float(-half_bend), local_t))
			elif t < 0.35:
				cx = -half_bend
			elif t < 0.65:
				var local_t: float = (t - 0.35) / 0.3
				cx = int(lerpf(float(-half_bend), float(half_bend), local_t))
			elif t < 0.88:
				cx = half_bend
			else:
				var local_t: float = (t - 0.88) / 0.12
				cx = int(lerpf(float(half_bend), 0.0, local_t))
			path_centers[yi] = cx

	# Compute 4 grass patches at 25%, 40%, 60%, 75% along route, alternating sides
	var grass_patches: Array = []
	var patch_positions: Array = [0.25, 0.40, 0.60, 0.75]
	for pi in patch_positions.size():
		var frac: float = patch_positions[pi]
		var primary_coord: int = int(lerpf(float(-inner), float(inner), frac))
		var center_cross: int = path_centers.get(primary_coord, 0)
		var on_right: bool = (pi % 2 == 0)  # Alternate sides
		var patch_w: int = 7
		var patch_h: int = 9
		var gap: int = 4  # tiles from path center to patch edge
		var origin: Vector2i
		if is_horizontal:
			# Primary=X, cross=Y
			var py: int = center_cross + gap if on_right else center_cross - gap - patch_h
			origin = Vector2i(primary_coord - patch_w / 2, py)
		else:
			# Primary=Y, cross=X
			var px: int = center_cross + gap if on_right else center_cross - gap - patch_w
			origin = Vector2i(px, primary_coord - patch_h / 2)
		grass_patches.append({"origin": origin, "size": Vector2i(patch_w, patch_h)})

	return {
		"path_centers": path_centers,
		"grass_patches": grass_patches,
		"is_horizontal": is_horizontal,
		"open_edges": open_edges,
	}

func _setup_route_tilemap(tile_set: TileSet, map_size: int) -> void:
	var source := TileSetAtlasSource.new()
	var tex := AssetRegistry.load_texture(AssetRegistry.tileset_route)
	if tex:
		source.texture = tex
		source.texture_region_size = Vector2i(16, 16)
		source.create_tile(Vector2i(0, 0))  # grass
		source.create_tile(Vector2i(1, 0))  # path
		source.create_tile(Vector2i(2, 0))  # tree
		tile_set.add_source(source, 0)

	tile_map.tile_set = tile_set

	var GRASS := Vector2i(0, 0)
	var PATH := Vector2i(1, 0)
	var TREE := Vector2i(2, 0)

	# Compute S-curve layout
	_route_layout = _compute_route_layout(map_size)
	var path_centers: Dictionary = _route_layout["path_centers"]
	var grass_patches: Array = _route_layout["grass_patches"]
	var is_horizontal: bool = _route_layout["is_horizontal"]
	var open_edges: Array = _route_layout["open_edges"]

	# 1. Base fill: all grass
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			tile_map.set_cell(Vector2i(x, y), 0, GRASS)

	# 2. Tree border (2 tiles thick) with openings at transitions
	for x in range(-map_size, map_size):
		for y in range(-map_size, map_size):
			if abs(x) >= map_size - 2 or abs(y) >= map_size - 2:
				var is_opening := false
				if "north" in open_edges and y <= -(map_size - 2) and abs(x) < 5:
					is_opening = true
				if "south" in open_edges and y >= map_size - 2 and abs(x) < 5:
					is_opening = true
				if "east" in open_edges and x >= map_size - 2 and abs(y) < 5:
					is_opening = true
				if "west" in open_edges and x <= -(map_size - 2) and abs(y) < 5:
					is_opening = true
				if is_opening:
					tile_map.set_cell(Vector2i(x, y), 0, PATH)
				else:
					tile_map.set_cell(Vector2i(x, y), 0, TREE)

	# 3. S-curve path (3 tiles wide)
	for coord in path_centers:
		var center: int = path_centers[coord]
		if is_horizontal:
			for dy in range(-1, 2):
				tile_map.set_cell(Vector2i(coord, center + dy), 0, PATH)
		else:
			for dx in range(-1, 2):
				tile_map.set_cell(Vector2i(center + dx, coord), 0, PATH)

	# 4. Tall grass patches - use modulated grass tiles
	# Build a set of grass patch positions for quick lookup
	var grass_tile_set: Dictionary = {}
	for patch in grass_patches:
		var origin: Vector2i = patch["origin"]
		var psize: Vector2i = patch["size"]
		for gx in range(origin.x, origin.x + psize.x):
			for gy in range(origin.y, origin.y + psize.y):
				grass_tile_set[Vector2i(gx, gy)] = true
				tile_map.set_cell(Vector2i(gx, gy), 0, GRASS)

	# 5. Tree corridors: 1-tile tree line on path-facing side of each patch, with 3-tile gap
	for patch in grass_patches:
		var origin: Vector2i = patch["origin"]
		var psize: Vector2i = patch["size"]
		if is_horizontal:
			# Corridor is a horizontal line above or below the patch
			var path_y_at_patch: int = path_centers.get(origin.x + psize.x / 2, 0)
			var patch_center_y: int = origin.y + psize.y / 2
			if patch_center_y > path_y_at_patch:
				# Patch is below path - corridor on top edge
				var corr_y: int = origin.y - 1
				for cx in range(origin.x, origin.x + psize.x):
					var dist_from_center: int = abs(cx - (origin.x + psize.x / 2))
					if dist_from_center > 1:
						tile_map.set_cell(Vector2i(cx, corr_y), 0, TREE)
			else:
				# Patch is above path - corridor on bottom edge
				var corr_y: int = origin.y + psize.y
				for cx in range(origin.x, origin.x + psize.x):
					var dist_from_center: int = abs(cx - (origin.x + psize.x / 2))
					if dist_from_center > 1:
						tile_map.set_cell(Vector2i(cx, corr_y), 0, TREE)
		else:
			# Corridor is a vertical line left or right of the patch
			var path_x_at_patch: int = path_centers.get(origin.y + psize.y / 2, 0)
			var patch_center_x: int = origin.x + psize.x / 2
			if patch_center_x > path_x_at_patch:
				# Patch is right of path - corridor on left edge
				var corr_x: int = origin.x - 1
				for cy in range(origin.y, origin.y + psize.y):
					var dist_from_center: int = abs(cy - (origin.y + psize.y / 2))
					if dist_from_center > 1:
						tile_map.set_cell(Vector2i(corr_x, cy), 0, TREE)
			else:
				# Patch is left of path - corridor on right edge
				var corr_x: int = origin.x + psize.x
				for cy in range(origin.y, origin.y + psize.y):
					var dist_from_center: int = abs(cy - (origin.y + psize.y / 2))
					if dist_from_center > 1:
						tile_map.set_cell(Vector2i(corr_x, cy), 0, TREE)

	# 6. Scattered decorative trees (~8%) on remaining base grass only
	var area_seed: int = GameManager.current_area.hash()
	for x in range(-(map_size - 3), map_size - 3):
		for y in range(-(map_size - 3), map_size - 3):
			var pos := Vector2i(x, y)
			# Skip if already path, tree, or grass patch
			if tile_map.get_cell_atlas_coords(pos) != GRASS:
				continue
			if grass_tile_set.has(pos):
				continue
			# Skip tiles adjacent to the path (within 2 tiles)
			var near_path := false
			if is_horizontal:
				if path_centers.has(x):
					if abs(y - path_centers[x]) <= 3:
						near_path = true
			else:
				if path_centers.has(y):
					if abs(x - path_centers[y]) <= 3:
						near_path = true
			if near_path:
				continue
			var h: int = ((x * 73856093) ^ (y * 19349663) ^ area_seed) % 1000
			if h < 0:
				h = -h
			if h < 80:
				tile_map.set_cell(pos, 0, TREE)

	# 7. Collision on tree tiles only
	_add_tile_collision(source, TREE)

	# Apply tall grass visual tint via per-cell modulate is not available in TileMapLayer,
	# so we create colored marker sprites for grass patches instead
	for patch in grass_patches:
		var origin: Vector2i = patch["origin"]
		var psize: Vector2i = patch["size"]
		var marker := ColorRect.new()
		marker.color = Color(0.35, 0.55, 0.2, 0.35)
		marker.position = Vector2(origin.x * 16, origin.y * 16)
		marker.size = Vector2(psize.x * 16, psize.y * 16)
		marker.z_index = -1
		add_child(marker)

	tile_map.modulate = Color(0.85, 0.9, 0.75)

func _setup_interior_tilemap(tile_set: TileSet, area_config: Dictionary) -> void:
	var source := TileSetAtlasSource.new()
	var tex := AssetRegistry.load_texture(AssetRegistry.tileset_town)
	if not tex:
		tex = AssetRegistry.load_texture(AssetRegistry.tileset_route)
	if tex:
		source.texture = tex
		source.texture_region_size = Vector2i(16, 16)
		for i in 8:
			source.create_tile(Vector2i(i, 0))
		tile_set.add_source(source, 0)

	tile_map.tile_set = tile_set

	# Tile indices (same as town tileset)
	var PATH := Vector2i(1, 0)   # Floor
	var WALL := Vector2i(4, 0)   # Walls
	var FENCE := Vector2i(6, 0)  # Counters/furniture

	var isize: Vector2i = area_config.get("interior_size", Vector2i(16, 10))
	var itype: String = area_config.get("interior_type", "house")
	var half_w: int = isize.x / 2
	var half_h: int = isize.y / 2

	# 1. Fill interior rect with floor tiles
	for x in range(-half_w, half_w):
		for y in range(-half_h, half_h):
			tile_map.set_cell(Vector2i(x, y), 0, PATH)

	# 2. Wall perimeter
	for x in range(-half_w, half_w):
		tile_map.set_cell(Vector2i(x, -half_h), 0, WALL)
		tile_map.set_cell(Vector2i(x, half_h - 1), 0, WALL)
	for y in range(-half_h, half_h):
		tile_map.set_cell(Vector2i(-half_w, y), 0, WALL)
		tile_map.set_cell(Vector2i(half_w - 1, y), 0, WALL)

	# 3. Door opening at bottom center (2 tiles wide)
	tile_map.set_cell(Vector2i(-1, half_h - 1), 0, PATH)
	tile_map.set_cell(Vector2i(0, half_h - 1), 0, PATH)

	# 4. Type-specific layout
	match itype:
		"hospital": _layout_hospital_interior(half_w, half_h, FENCE, PATH)
		"shop": _layout_shop_interior(half_w, half_h, FENCE, PATH)
		"gym": _layout_gym_interior(half_w, half_h, FENCE, PATH)
		"house": _layout_house_interior(half_w, half_h, FENCE, PATH)

	# 5. Collision on walls and furniture
	_add_tile_collision(source, WALL)
	_add_tile_collision(source, FENCE)

	tile_map.modulate = Color(1.0, 1.0, 1.0)

func _layout_hospital_interior(hw: int, hh: int, FENCE: Vector2i, _PATH: Vector2i) -> void:
	# Counter across top with center gap
	var counter_y: int = -hh + 2
	for x in range(-hw + 1, hw - 1):
		if abs(x) > 1:  # Leave 3-tile gap in center
			tile_map.set_cell(Vector2i(x, counter_y), 0, FENCE)
	# Flower decorations in corners
	var FLOWERS := Vector2i(7, 0)
	tile_map.set_cell(Vector2i(-hw + 1, -hh + 1), 0, FLOWERS)
	tile_map.set_cell(Vector2i(hw - 2, -hh + 1), 0, FLOWERS)
	tile_map.set_cell(Vector2i(-hw + 1, hh - 2), 0, FLOWERS)
	tile_map.set_cell(Vector2i(hw - 2, hh - 2), 0, FLOWERS)

func _layout_shop_interior(hw: int, hh: int, FENCE: Vector2i, _PATH: Vector2i) -> void:
	# Counter near top
	var counter_y: int = -hh + 2
	for x in range(-hw + 1, hw - 1):
		if abs(x) > 1:
			tile_map.set_cell(Vector2i(x, counter_y), 0, FENCE)
	# Shelf lines along side walls
	for y in range(-hh + 3, hh - 2):
		tile_map.set_cell(Vector2i(-hw + 1, y), 0, FENCE)
		tile_map.set_cell(Vector2i(hw - 2, y), 0, FENCE)

func _layout_gym_interior(hw: int, hh: int, FENCE: Vector2i, _PATH: Vector2i) -> void:
	# Arena border pattern in center
	var arena_hw: int = hw / 2
	var arena_hh: int = hh / 2
	# Top and bottom arena lines
	for x in range(-arena_hw, arena_hw):
		tile_map.set_cell(Vector2i(x, -arena_hh), 0, FENCE)
		tile_map.set_cell(Vector2i(x, arena_hh - 1), 0, FENCE)
	# Left and right arena lines
	for y in range(-arena_hh, arena_hh):
		tile_map.set_cell(Vector2i(-arena_hw, y), 0, FENCE)
		tile_map.set_cell(Vector2i(arena_hw - 1, y), 0, FENCE)

func _layout_house_interior(hw: int, hh: int, FENCE: Vector2i, _PATH: Vector2i) -> void:
	# Table in corner
	tile_map.set_cell(Vector2i(-hw + 2, -hh + 2), 0, FENCE)
	tile_map.set_cell(Vector2i(-hw + 3, -hh + 2), 0, FENCE)
	# Simple furniture piece
	tile_map.set_cell(Vector2i(hw - 3, -hh + 2), 0, FENCE)

func _add_tile_collision(source: TileSetAtlasSource, atlas_coords: Vector2i) -> void:
	var tile_data := source.get_tile_data(atlas_coords, 0)
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
		npc.dialogue_lines = config.get("lines", ["Hello!"])
		if config.has("bubble"):
			npc.bubble_text = config["bubble"]
		if config.has("dialogue"):
			npc.dialogue_tree = config["dialogue"]
		npcs_container.add_child(npc)

func _spawn_trainers(area_config: Dictionary) -> void:
	var trainer_configs: Array = area_config.get("trainers", [])
	if trainer_configs.is_empty():
		return
	var trainer_scene := load("res://scenes/overworld/trainer.tscn") as PackedScene
	if not trainer_scene:
		return
	for config in trainer_configs:
		var trainer := trainer_scene.instantiate()
		trainer.position = config["pos"]
		trainer.trainer_id = config["trainer_id"]
		trainer.trainer_name = config["name"]
		trainer.monster_ids = config["monster_ids"]
		trainer.monster_levels = config["monster_levels"]
		trainer.dialogue_before = config["dialogue_before"]
		trainer.dialogue_after = config["dialogue_after"]
		trainer.is_gym_leader = config.get("is_gym_leader", false)
		trainer.badge_id = config.get("badge_id", "")
		# Line-of-sight direction
		var sight_str: String = config.get("sight_dir", "down")
		match sight_str:
			"up": trainer.sight_direction = Vector2.UP
			"left": trainer.sight_direction = Vector2.LEFT
			"right": trainer.sight_direction = Vector2.RIGHT
			_: trainer.sight_direction = Vector2.DOWN
		npcs_container.add_child(trainer)

func start_trainer_battle(trainer: Node) -> void:
	if GameManager.is_in_battle:
		return
	GameManager.is_in_battle = true
	var battle_scene_res := load("res://scenes/battle/battle_scene.tscn") as PackedScene
	if not battle_scene_res:
		print("ERROR: Failed to load battle scene!")
		GameManager.is_in_battle = false
		return
	var battle := battle_scene_res.instantiate()
	battle.is_trainer_battle = true
	battle.trainer_name = trainer.trainer_name
	battle.enemy_party_data = trainer.get_party()
	if battle.enemy_party_data.size() > 0:
		battle.wild_monster_data = battle.enemy_party_data[0]["data"]
		battle.wild_monster_level = battle.enemy_party_data[0]["level"]
	battle.battle_ended.connect(_on_trainer_battle_ended.bind(trainer))
	battle_layer.add_child(battle)

func _on_trainer_battle_ended(result: String, _overworld_id: int, trainer: Node) -> void:
	GameManager.is_in_battle = false
	GameManager.is_in_dialogue = false
	GameManager.advance_time(0.5)
	if result == "win":
		GameManager.mark_trainer_defeated(trainer.trainer_id)
		if trainer.is_gym_leader and trainer.badge_id != "":
			GameManager.earn_badge(trainer.badge_id)
		if trainer.has_method("on_defeated"):
			trainer.on_defeated()
		# Advance defeat_trainer quests
		for quest_id: String in GameManager.active_quests:
			var quest_def: Dictionary = GameManager.get_quest_def(quest_id)
			if quest_def.get("type", "") == "defeat_trainer" and quest_def.get("target", "") == trainer.trainer_id:
				GameManager.advance_quest(quest_id)

	# Auto-save after trainer battle
	SaveManager.save_game()

func _spawn_pc_terminals(area_config: Dictionary) -> void:
	var terminal_configs: Array = area_config.get("pc_terminals", [])
	if terminal_configs.is_empty():
		return
	var terminal_scene := load("res://scenes/overworld/pc_terminal.tscn") as PackedScene
	if not terminal_scene:
		return
	for config in terminal_configs:
		var terminal := terminal_scene.instantiate()
		terminal.position = config["pos"]
		npcs_container.add_child(terminal)

func _spawn_wild_monsters(area_config: Dictionary) -> void:
	if area_config.get("safe_zone", false):
		return

	var wild_scene := load("res://scenes/overworld/wild_monster.tscn") as PackedScene
	if not wild_scene:
		return

	var wild_configs: Array = area_config.get("wild_monsters", [])
	var current_area: String = GameManager.current_area
	var patches: Array = _route_layout.get("grass_patches", [])

	for i in wild_configs.size():
		var config := wild_configs[i] as Dictionary
		if GameManager.is_area_monster_defeated(current_area, i + 1):
			continue
		var wild := wild_scene.instantiate()

		# Distribute monsters into grass patches round-robin if layout exists
		if patches.size() > 0:
			var patch_idx: int = i % patches.size()
			var patch: Dictionary = patches[patch_idx]
			var origin: Vector2i = patch["origin"]
			var psize: Vector2i = patch["size"]
			# Spread monsters within patch based on index
			var monsters_per_patch: int = maxi(1, wild_configs.size() / patches.size())
			var local_idx: int = i / patches.size()
			var cols: int = maxi(1, psize.x / 2)
			var ox: int = (local_idx % cols) * 2 + 1
			var oy: int = (local_idx / cols) * 2 + 1
			ox = mini(ox, psize.x - 1)
			oy = mini(oy, psize.y - 1)
			wild.position = Vector2((origin.x + ox) * 16 + 8, (origin.y + oy) * 16 + 8)
		else:
			wild.position = config["pos"]

		wild.monster_data_id = config["monster_id"]
		wild.overworld_id = i + 1
		wild.level_min = config["level_min"]
		wild.level_max = config["level_max"]
		wild_monsters_container.add_child(wild)

func _spawn_pois(area_config: Dictionary) -> void:
	var poi_configs: Array = area_config.get("pois", [])
	if poi_configs.is_empty():
		return

	var npc_scene := load("res://scenes/overworld/npc.tscn") as PackedScene

	for poi in poi_configs:
		var poi_type: String = poi.get("type", "sign")
		var poi_pos: Vector2 = poi["pos"]

		match poi_type:
			"sign":
				# Sign: NPC that gives route info
				if npc_scene:
					var npc := npc_scene.instantiate()
					npc.position = poi_pos
					npc.dialogue_lines = poi.get("lines", ["..."])
					npc.bubble_text = "Sign"
					npcs_container.add_child(npc)

			"rest_stop":
				# Rest stop: small path area with bench-like NPC
				if npc_scene:
					var npc := npc_scene.instantiate()
					npc.position = poi_pos
					npc.dialogue_lines = ["A quiet rest stop.\nYou feel refreshed!"]
					npc.bubble_text = "Rest here..."
					npc.dialogue_tree = [
						{"id": "start", "text": "A peaceful rest stop.\nWant to rest and heal\nyour monsters?", "speaker": "Rest Stop", "choices": [
							{"label": "Rest here", "next": "heal"},
							{"label": "Keep going", "next": "bye"},
						]},
						{"id": "heal", "text": "You rest for a while...\nYour monsters feel refreshed!", "speaker": "Rest Stop", "action": "heal_party"},
						{"id": "bye", "text": "Safe travels!", "speaker": "Rest Stop"},
					]
					npcs_container.add_child(npc)

			"clearing":
				# Clearing: NPC with info or item hint
				if npc_scene:
					var npc := npc_scene.instantiate()
					npc.position = poi_pos
					npc.dialogue_lines = poi.get("npc_lines", ["A hidden clearing..."])
					npc.bubble_text = poi.get("npc_bubble", "Over here!")
					npcs_container.add_child(npc)

			"berry_tree":
				# Berry tree: NPC that gives a potion once
				if npc_scene:
					var npc := npc_scene.instantiate()
					npc.position = poi_pos
					npc.dialogue_lines = ["A berry tree! You found\na Potion!"]
					npc.bubble_text = "Berries!"
					npc.dialogue_tree = [
						{"id": "start", "text": "A wild berry tree!\nThe berries look ripe.", "speaker": "Berry Tree", "choices": [
							{"label": "Pick berries", "next": "pick"},
							{"label": "Leave it", "next": "bye"},
						]},
						{"id": "pick", "text": "You picked some berries!\nObtained a Potion!", "speaker": "Berry Tree", "action": "give_item:potion:1"},
						{"id": "bye", "text": "The berries sway in the breeze.", "speaker": "Berry Tree"},
					]
					npcs_container.add_child(npc)

func _spawn_building_doors(area_config: Dictionary) -> void:
	var buildings: Array = area_config.get("buildings", [])
	if buildings.is_empty():
		return
	var door_scene := load("res://scenes/overworld/door.tscn") as PackedScene
	if not door_scene:
		return
	var parent_area: String = GameManager.current_area
	for i in buildings.size():
		var bldg: Dictionary = buildings[i]
		var bpos: Vector2i = bldg["pos"]
		var btype: String = bldg.get("type", "house")
		var bsize: Vector2i = bldg.get("size", _default_building_size(btype))
		# Door position: bottom-center of building, in pixel coords
		var door_x: float = (float(bpos.x) + float(bsize.x) / 2.0) * 16.0 + 8.0
		var door_y: float = (float(bpos.y) + float(bsize.y)) * 16.0 + 8.0
		var door := door_scene.instantiate()
		door.position = Vector2(door_x, door_y)
		door.target_area = "%s_interior_%s_%d" % [parent_area, btype, i]
		door.is_exit = false
		door.building_name = btype
		# Return position: one tile south of door
		door.return_position = Vector2(door_x, door_y + 16.0)
		npcs_container.add_child(door)

func _spawn_interior_exit(area_config: Dictionary) -> void:
	var isize: Vector2i = area_config.get("interior_size", Vector2i(16, 10))
	var half_h: int = isize.y / 2

	# Exit door at bottom center
	var door_scene := load("res://scenes/overworld/door.tscn") as PackedScene
	if door_scene:
		var exit_door := door_scene.instantiate()
		exit_door.position = Vector2(0, (half_h - 1) * 16)
		exit_door.is_exit = true
		exit_door.target_area = ""  # Not used for exit
		var prompt: Label = exit_door.get_node("PromptLabel")
		if prompt:
			prompt.text = "Exit"
		npcs_container.add_child(exit_door)

	# Walk-through exit zone below door (auto-exit like classic Pokemon)
	var exit_zone := Area2D.new()
	exit_zone.name = "ExitZone"
	exit_zone.collision_layer = 0
	exit_zone.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 16)
	shape.shape = rect
	exit_zone.position = Vector2(0, half_h * 16)
	exit_zone.add_child(shape)
	add_child(exit_zone)
	exit_zone.body_entered.connect(_on_interior_exit_entered)

func _on_interior_exit_entered(_body: Node2D) -> void:
	if GameManager.is_in_battle or GameManager.is_in_menu or GameManager.is_in_dialogue:
		return
	GameManager.is_in_building = false
	GameManager.current_area = GameManager.building_return_area
	GameManager.set_area_player_position(GameManager.building_return_area, GameManager.building_return_position)
	GameManager.building_return_area = ""
	GameManager.building_return_position = Vector2.ZERO
	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")

func _setup_interior_camera(area_config: Dictionary) -> void:
	var isize: Vector2i = area_config.get("interior_size", Vector2i(16, 10))
	var half_w: int = isize.x / 2
	var half_h: int = isize.y / 2
	if player and player.has_node("Camera2D"):
		var cam: Camera2D = player.get_node("Camera2D")
		cam.limit_left = -half_w * 16
		cam.limit_right = half_w * 16
		cam.limit_top = -half_h * 16
		cam.limit_bottom = half_h * 16

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
	GameManager.advance_time(1.0)
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
		"route2": "Route 2",
		"town2": "Coral City",
		"route3": "Route 3",
		"town3": "Ember Ridge",
		"route4": "Route 4",
		"town4": "Verdant Grove",
		"route5": "Route 5",
		"town5": "Stormhaven",
	}
	var display_name: String = ""
	var area_config: Dictionary = _get_area_config()
	if area_config.has("interior_display_name"):
		display_name = area_config["interior_display_name"]
	else:
		display_name = area_names.get(GameManager.current_area, GameManager.current_area)

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

# --- Overworld swipe defeat (no XP, convenience only) ---

func on_monster_swiped(ow_id: int) -> void:
	GameManager.mark_area_monster_defeated(GameManager.current_area, ow_id)

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
	GameManager.advance_time(0.5)
	var removed := (result == "win" or result == "catch")
	if removed:
		GameManager.mark_area_monster_defeated(GameManager.current_area, overworld_id)

	# Advance catch-count quests
	if result == "catch":
		for quest_id: String in GameManager.active_quests:
			var quest_def: Dictionary = GameManager.get_quest_def(quest_id)
			if quest_def.get("type", "") == "catch_count":
				GameManager.advance_quest(quest_id)

	# Auto-save after battle
	SaveManager.save_game()

	# Notify the wild monster
	for child in wild_monsters_container.get_children():
		if child.has_method("get_overworld_id") and child.get_overworld_id() == overworld_id:
			if child.has_method("on_battle_ended"):
				child.on_battle_ended(removed)
			break

func _show_dialogue(lines: Array) -> Node:
	var dialogue_scene := load("res://scenes/overworld/dialogue_box.tscn") as PackedScene
	if dialogue_scene:
		var dialogue := dialogue_scene.instantiate()
		dialogue.set_lines(lines)
		ui_layer.add_child(dialogue)
		return dialogue
	return null

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

# ── Dialogue Tree ──

func _show_dialogue_tree(nodes: Array) -> void:
	var tree_scene := load("res://scenes/overworld/dialogue_tree.tscn") as PackedScene
	if tree_scene:
		var tree := tree_scene.instantiate()
		tree.set_tree(nodes)
		tree.dialogue_action.connect(_handle_dialogue_action)
		ui_layer.add_child(tree)

func _handle_dialogue_action(action_str: String) -> void:
	var parts: PackedStringArray = action_str.split(":")
	var action_type: String = parts[0]
	match action_type:
		"start_quest":
			if parts.size() >= 2:
				GameManager.start_quest(parts[1])
		"complete_quest":
			if parts.size() >= 2:
				GameManager.complete_quest(parts[1])
		"give_item":
			if parts.size() >= 3:
				GameManager.add_item(parts[1], int(parts[2]))
			elif parts.size() >= 2:
				GameManager.add_item(parts[1])
		"heal_party":
			GameManager.heal_all_party()
		"open_shop":
			_open_shop()

func _open_shop() -> void:
	var shop_scene := load("res://scenes/ui/shop_ui.tscn") as PackedScene
	if shop_scene:
		var shop := shop_scene.instantiate()
		ui_layer.add_child(shop)

# ── Cutscene ──

func play_cutscene(steps: Array) -> void:
	var cutscene_script := load("res://scripts/overworld/cutscene_player.gd") as GDScript
	if cutscene_script:
		var cutscene := Node.new()
		cutscene.set_script(cutscene_script)
		add_child(cutscene)
		cutscene.play(steps, player.camera, ui_layer)

# ── Day/Night ──

func _setup_day_night() -> void:
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.color = GameManager.get_time_color()
	add_child(_canvas_modulate)
	if GameManager.has_signal("time_changed"):
		GameManager.time_changed.connect(_on_time_changed)

func _on_time_changed(_new_period: String) -> void:
	if _canvas_modulate:
		var tween := create_tween()
		tween.tween_property(_canvas_modulate, "color", GameManager.get_time_color(), 1.0)

# ── Weather ──

func _setup_weather(area_config: Dictionary) -> void:
	var weather_type: String = area_config.get("weather", "clear")
	if weather_type == "clear":
		return
	var weather_script := load("res://scripts/overworld/weather_system.gd") as GDScript
	if weather_script:
		_weather_system = Node2D.new()
		_weather_system.set_script(weather_script)
		add_child(_weather_system)
		_weather_system.setup(ui_layer)
		_weather_system.set_weather(weather_type)
