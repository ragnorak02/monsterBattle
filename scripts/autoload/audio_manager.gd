extends Node

var _music_player: AudioStreamPlayer
var _music_player_2: AudioStreamPlayer  # For crossfade
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_music_path: String = ""

const SFX_POOL_SIZE := 8
const CROSSFADE_DURATION := 0.5

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	_music_player_2 = AudioStreamPlayer.new()
	_music_player_2.bus = "Master"
	add_child(_music_player_2)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

func play_music(path: String, crossfade: bool = true) -> void:
	if path == _current_music_path:
		return
	_current_music_path = path

	if not ResourceLoader.exists(path):
		push_warning("AudioManager: Music file not found: " + path)
		return

	var stream := load(path) as AudioStream
	if not stream:
		return

	if crossfade and _music_player.playing:
		_music_player_2.stream = stream
		_music_player_2.volume_db = -40.0
		_music_player_2.play()

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_music_player, "volume_db", -40.0, CROSSFADE_DURATION)
		tween.tween_property(_music_player_2, "volume_db", 0.0, CROSSFADE_DURATION)
		await tween.finished

		_music_player.stop()
		# Swap players
		var temp := _music_player
		_music_player = _music_player_2
		_music_player_2 = temp
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade: bool = true) -> void:
	_current_music_path = ""
	if fade and _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, CROSSFADE_DURATION)
		await tween.finished
		_music_player.stop()
	else:
		_music_player.stop()

func play_sfx(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if not stream:
		return

	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = 0.0
			player.play()
			return

	# All busy, use first one
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()
