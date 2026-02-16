extends Control

@onready var boy_button: Button = %BoyButton if has_node("%BoyButton") else $VBox/ButtonContainer/BoyContainer/BoyButton
@onready var girl_button: Button = %GirlButton if has_node("%GirlButton") else $VBox/ButtonContainer/GirlContainer/GirlButton
@onready var boy_sprite: TextureRect = $VBox/ButtonContainer/BoyContainer/BoySprite
@onready var girl_sprite: TextureRect = $VBox/ButtonContainer/GirlContainer/GirlSprite

func _ready() -> void:
	boy_button.pressed.connect(_on_boy_selected)
	girl_button.pressed.connect(_on_girl_selected)
	boy_button.grab_focus()

	# Load preview sprites
	var boy_tex := load("res://assets/sprites/player/player_boy.png") as Texture2D
	var girl_tex := load("res://assets/sprites/player/player_girl.png") as Texture2D
	if boy_tex:
		boy_sprite.texture = boy_tex
	if girl_tex:
		girl_sprite.texture = girl_tex

func _on_boy_selected() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.wav")
	GameManager.player_gender = "boy"
	SceneManager.change_scene("res://scenes/starter_select.tscn")

func _on_girl_selected() -> void:
	AudioManager.play_sfx("res://assets/audio/sfx/select.wav")
	GameManager.player_gender = "girl"
	SceneManager.change_scene("res://scenes/starter_select.tscn")
