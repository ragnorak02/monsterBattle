extends Control

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var exit_button: Button = $VBox/ExitButton

func _ready() -> void:
	continue_button.visible = true

	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_on_settings)
	exit_button.pressed.connect(_on_exit)

	continue_button.grab_focus()

func _on_continue() -> void:
	# Quick-start: skip gender/starter select, jump straight into overworld
	GameManager.player_gender = "boy"
	GameManager.gold = 100
	GameManager.player_party = []
	GameManager.pc_storage = []
	GameManager.inventory = {}
	GameManager.badges = {}
	GameManager.defeated_trainers = {}
	GameManager.active_quests = {}
	GameManager.completed_quests = {}
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	GameManager.area_player_positions = {}
	GameManager.area_defeated_monsters = {}
	GameManager.defeated_monster_ids = []

	# Create starter monster (monster #1) at level 5
	var starter_data: Resource = MonsterDB.get_monster(1)
	if starter_data:
		var starter := MonsterInstance.new(starter_data, 5)
		GameManager.add_to_party(starter)
		GameManager.mark_monster_caught(int(starter_data.get("id")))

	# Give starter items
	GameManager.add_item("potion", 5)
	GameManager.add_item("antidote", 3)
	GameManager.add_item("capture_ball", 10)

	# Set spawn position at town north entrance
	GameManager.current_area = "town"
	GameManager.set_area_player_position("town", Vector2(0, -576))

	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")

func _on_new_game() -> void:
	SceneManager.change_scene("res://scenes/gender_select.tscn")

func _on_settings() -> void:
	print("TitleMenu: Settings not yet implemented")

func _on_exit() -> void:
	get_tree().quit()
