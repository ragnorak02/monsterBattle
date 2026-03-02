extends Control

@onready var boy_button: Button = %BoyButton if has_node("%BoyButton") else $VBox/ButtonContainer/BoyContainer/BoyButton
@onready var girl_button: Button = %GirlButton if has_node("%GirlButton") else $VBox/ButtonContainer/GirlContainer/GirlButton
@onready var boy_sprite: TextureRect = $VBox/ButtonContainer/BoyContainer/BoySprite
@onready var girl_sprite: TextureRect = $VBox/ButtonContainer/GirlContainer/GirlSprite
@onready var hint_bar: PanelContainer = $ControllerHintBar

func _ready() -> void:
	boy_button.pressed.connect(_on_boy_selected)
	girl_button.pressed.connect(_on_girl_selected)
	boy_button.grab_focus()

	# Load preview sprites — crop top-left 32x32 frame (forward-facing idle)
	var boy_tex := load("res://assets/sprites/player/player_boy.png") as Texture2D
	var girl_tex := load("res://assets/sprites/player/player_girl.png") as Texture2D
	if boy_tex:
		boy_sprite.texture = _make_portrait(boy_tex)
	if girl_tex:
		girl_sprite.texture = _make_portrait(girl_tex)

	if hint_bar:
		hint_bar.set_hints([
			{"icon": "btn_a", "label": "Select"},
			{"icon": "dpad", "label": "Navigate"},
		])

func _make_portrait(full_sheet: Texture2D) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = full_sheet
	atlas.region = Rect2(0, 0, 32, 32)
	return atlas

func _on_boy_selected() -> void:
	AudioManager.play_sfx(AssetRegistry.sfx_select)
	GameManager.player_gender = "boy"
	SceneManager.change_scene("res://scenes/starter_select.tscn")

func _on_girl_selected() -> void:
	AudioManager.play_sfx(AssetRegistry.sfx_select)
	GameManager.player_gender = "girl"
	SceneManager.change_scene("res://scenes/starter_select.tscn")
