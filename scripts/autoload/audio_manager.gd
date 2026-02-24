extends Node
## Global audio manager. Handles SFX, music, and ambient audio playback.
## Gracefully skips missing audio files with a warning instead of crashing.

const SFX_DIR := "res://resources/audio/sfx/"
const MUSIC_DIR := "res://resources/audio/music/"
const AMBIENT_DIR := "res://resources/audio/ambient/"

var _sfx_player: AudioStreamPlayer
var _sfx_player_2: AudioStreamPlayer  # second channel for overlapping SFX
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer

# Preloaded streams cache: name -> AudioStream
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _ambient_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	_sfx_player_2 = AudioStreamPlayer.new()
	_sfx_player_2.bus = "SFX"
	add_child(_sfx_player_2)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = "SFX"
	add_child(_ui_player)

	_preload_all()


func _preload_all() -> void:
	_preload_dir(SFX_DIR, _sfx_cache)
	_preload_dir(MUSIC_DIR, _music_cache)
	_preload_dir(AMBIENT_DIR, _ambient_cache)


func _preload_dir(dir_path: String, cache: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			# Accept .ogg, .wav, .mp3 — skip .import files
			var ext := file.get_extension().to_lower()
			if ext in ["ogg", "wav", "mp3"]:
				var sound_name := file.get_basename()
				var full_path := dir_path + file
				var stream := load(full_path) as AudioStream
				if stream:
					cache[sound_name] = stream
		file = dir.get_next()
	dir.list_dir_end()


func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_cache.get(sound_name)
	if not stream:
		push_warning("AudioManager: SFX not found: '%s'" % sound_name)
		return

	# Use whichever SFX player isn't currently playing, for overlap
	var player := _sfx_player if not _sfx_player.playing else _sfx_player_2
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func play_ui(sound_name: String) -> void:
	var stream: AudioStream = _sfx_cache.get(sound_name)
	if not stream:
		push_warning("AudioManager: UI SFX not found: '%s'" % sound_name)
		return
	_ui_player.stream = stream
	_ui_player.volume_db = -5.0
	_ui_player.play()


func play_music(sound_name: String, volume_db: float = -10.0) -> void:
	var stream: AudioStream = _music_cache.get(sound_name)
	if not stream:
		push_warning("AudioManager: Music not found: '%s'" % sound_name)
		return
	if _music_player.stream == stream and _music_player.playing:
		return  # Already playing this track
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_ambient(sound_name: String, volume_db: float = -8.0) -> void:
	var stream: AudioStream = _ambient_cache.get(sound_name)
	if not stream:
		push_warning("AudioManager: Ambient not found: '%s'" % sound_name)
		return
	if _ambient_player.stream == stream and _ambient_player.playing:
		return
	_ambient_player.stream = stream
	_ambient_player.volume_db = volume_db
	_ambient_player.play()


func stop_ambient() -> void:
	_ambient_player.stop()


func set_bus_volume(bus_name: String, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)


func set_bus_mute(bus_name: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)
