extends Node

@export_category("Music")
@export var menu_music: AudioStream
@export var game_music: AudioStream

@export_category("UI SFX")
@export var ui_hover_sfx: AudioStream
@export var ui_click_sfx: AudioStream
@export var pause_on_sfx: AudioStream
@export var pause_off_sfx: AudioStream

@export_category("Player SFX")
@export var jump_sfx: AudioStream
@export var dash_sfx: AudioStream
@export var parry_sfx: AudioStream
@export var death_sfx: AudioStream

@export_category("World SFX")
@export var button_press_sfx: AudioStream
@export var button_release_sfx: AudioStream
@export var gate_unlock_sfx: AudioStream
@export var gate_enter_sfx: AudioStream
@export var pickup_sfx: AudioStream
@export var bounce_sfx: AudioStream

@export_category("Pools")
@export var sfx_pool_size: int = 8
@export var ui_pool_size: int = 6

@export_category("Volume")
@export var music_volume_db: float = -4.0
@export var game_music_volume_db: float = -2.0
@export var ui_volume_boost_db: float = 7.0
@export var sfx_volume_boost_db: float = 8.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _ui_index: int = 0
var _current_music: AudioStream

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_create_music_player()
	_create_pool(_sfx_players, "SFX", max(1, sfx_pool_size))
	_create_pool(_ui_players, "UI", max(1, ui_pool_size))

func play_menu_music() -> void:
	_play_music_stream(menu_music, music_volume_db)

func play_game_music() -> void:
	_play_music_stream(game_music if game_music else menu_music, game_music_volume_db)

func stop_music() -> void:
	_music_player.stop()
	_current_music = null

func play_ui_hover() -> void:
	_play_stream(ui_hover_sfx, true, -9.0, randf_range(0.98, 1.04))

func play_ui_click() -> void:
	_play_stream(ui_click_sfx, true, -3.0, randf_range(0.98, 1.03))

func play_pause_toggle(paused: bool) -> void:
	_play_stream(pause_on_sfx if paused else pause_off_sfx, true, -2.5)

func play_jump() -> void:
	_play_stream(jump_sfx, false, -2.0, randf_range(0.98, 1.04))

func play_dash() -> void:
	_play_stream(dash_sfx, false, -1.5, randf_range(0.97, 1.02))

func play_parry() -> void:
	_play_stream(parry_sfx, false, 1.5, randf_range(0.99, 1.01))

func play_death() -> void:
	_play_stream(death_sfx, false, -1.0)

func play_button_press() -> void:
	_play_stream(button_press_sfx, false, -2.0)

func play_button_release() -> void:
	_play_stream(button_release_sfx, false, -5.0)

func play_gate_unlock() -> void:
	_play_stream(gate_unlock_sfx, false, -1.0)

func play_gate_enter() -> void:
	_play_stream(gate_enter_sfx, false, -2.0)

func play_pickup() -> void:
	_play_stream(pickup_sfx, false, -1.0, randf_range(0.99, 1.03))

func play_bounce() -> void:
	_play_stream(bounce_sfx, false, -1.0, randf_range(0.96, 1.02))

func _play_music_stream(stream: AudioStream, volume_db: float) -> void:
	if not stream:
		return
	if _current_music == stream and _music_player.playing:
		_music_player.volume_db = volume_db
		return
	
	_current_music = stream
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func _play_stream(stream: AudioStream, use_ui_pool: bool, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	
	var player := _next_player(_ui_players, true) if use_ui_pool else _next_player(_sfx_players, false)
	player.stop()
	player.stream = stream
	player.volume_db = volume_db + (ui_volume_boost_db if use_ui_pool else sfx_volume_boost_db)
	player.pitch_scale = pitch_scale
	player.play()

func _create_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

func _create_pool(target: Array[AudioStreamPlayer], bus_name: String, count: int) -> void:
	for i in count:
		var player := AudioStreamPlayer.new()
		player.bus = bus_name
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		target.append(player)

func _next_player(pool: Array[AudioStreamPlayer], is_ui: bool) -> AudioStreamPlayer:
	if pool.is_empty():
		return _music_player
	
	var index := _ui_index if is_ui else _sfx_index
	var player := pool[index % pool.size()]
	if is_ui:
		_ui_index += 1
	else:
		_sfx_index += 1
	return player

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	
	AudioServer.add_bus(AudioServer.bus_count)
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
