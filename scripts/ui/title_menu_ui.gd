extends Control

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var exit_button: Button = $VBox/ExitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	version_label.text = GameManager.GAME_VERSION
	AudioManager.play_music(AssetRegistry.music_town)

	if SaveManager.has_save():
		continue_button.visible = true
		continue_button.grab_focus()
	else:
		continue_button.visible = false
		new_game_button.grab_focus()

	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_on_settings)
	exit_button.pressed.connect(_on_exit)

	# Wire select SFX on focus for all buttons
	for btn in [new_game_button, continue_button, settings_button, exit_button]:
		btn.focus_entered.connect(func(): AudioManager.play_sfx(AssetRegistry.sfx_select))

func _on_continue() -> void:
	if not SaveManager.has_save():
		print("TitleMenu: No save data found")
		return

	var success := SaveManager.load_game()
	if not success:
		print("TitleMenu: Failed to load save data")
		return

	# Safety: sync registry from owned monsters
	for monster: MonsterInstance in GameManager.player_party:
		if monster.base_data:
			var mid: int = int(monster.base_data.get("id"))
			GameManager.mark_monster_seen(mid)
			GameManager.mark_monster_caught(mid)

	SceneManager.change_scene("res://scenes/overworld/overworld.tscn")

func _on_new_game() -> void:
	SceneManager.change_scene("res://scenes/gender_select.tscn")

func _on_settings() -> void:
	print("TitleMenu: Settings not yet implemented")

func _on_exit() -> void:
	get_tree().quit()
