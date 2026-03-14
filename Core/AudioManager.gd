extends Node

const DEFAULT_MUSIC_PATH := "res://Scenes/UZlabak (1).mp3"
const SAMPLE_RATE := 22050

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _ui_index: int = 0
var _current_music_path: String = ""
var _cue_streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("UI")
	_create_music_player()
	_create_pool(_sfx_players, "SFX", 8)
	_create_pool(_ui_players, "UI", 6)
	_build_cues()

func play_menu_music() -> void:
	play_music(DEFAULT_MUSIC_PATH, -12.0)

func play_game_music() -> void:
	play_music(DEFAULT_MUSIC_PATH, -10.0)

func play_music(path: String, volume_db: float = -10.0) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _current_music_path == path and _music_player.playing:
		_music_player.volume_db = volume_db
		return
	
	var stream := load(path) as AudioStream
	if not stream:
		return
	
	_current_music_path = path
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()
	_current_music_path = ""

func play_ui_hover() -> void:
	_play_named("ui_hover", true, -16.0, randf_range(0.98, 1.04))

func play_ui_click() -> void:
	_play_named("ui_click", true, -10.0, randf_range(0.98, 1.03))

func play_pause_toggle(paused: bool) -> void:
	_play_named("pause_on" if paused else "pause_off", true, -10.0)

func play_jump() -> void:
	_play_named("jump", false, -8.0, randf_range(0.98, 1.04))

func play_dash() -> void:
	_play_named("dash", false, -7.0, randf_range(0.97, 1.02))

func play_parry() -> void:
	_play_named("parry", false, -4.0, randf_range(0.99, 1.01))

func play_death() -> void:
	_play_named("death", false, -6.0)

func play_button_press() -> void:
	_play_named("button_press", false, -8.0)

func play_button_release() -> void:
	_play_named("button_release", false, -12.0)

func play_gate_unlock() -> void:
	_play_named("gate_unlock", false, -6.0)

func play_gate_enter() -> void:
	_play_named("gate_enter", false, -8.0)

func play_pickup() -> void:
	_play_named("pickup", false, -8.0, randf_range(0.99, 1.03))

func play_bounce() -> void:
	_play_named("bounce", false, -7.0, randf_range(0.96, 1.02))

func _play_named(cue_name: String, use_ui_pool: bool, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream := _cue_streams.get(cue_name) as AudioStream
	if not stream:
		return
	
	var player := _next_player(_ui_players, true) if use_ui_pool else _next_player(_sfx_players, false)
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
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

func _build_cues() -> void:
	_cue_streams = {
		"ui_hover": _make_tone(920.0, 1240.0, 0.04, "sine", 0.18),
		"ui_click": _make_tone(740.0, 460.0, 0.08, "square", 0.22),
		"pause_on": _make_tone(420.0, 300.0, 0.08, "triangle", 0.22),
		"pause_off": _make_tone(280.0, 420.0, 0.08, "triangle", 0.22),
		"jump": _make_tone(260.0, 420.0, 0.11, "square", 0.26),
		"dash": _make_tone(160.0, 620.0, 0.09, "saw", 0.24),
		"parry": _make_tone(1180.0, 720.0, 0.09, "square", 0.26),
		"death": _make_tone(220.0, 70.0, 0.22, "saw", 0.24),
		"button_press": _make_tone(180.0, 260.0, 0.08, "triangle", 0.24),
		"button_release": _make_tone(220.0, 170.0, 0.08, "triangle", 0.18),
		"gate_unlock": _make_tone(360.0, 880.0, 0.24, "sine", 0.24),
		"gate_enter": _make_tone(680.0, 980.0, 0.12, "sine", 0.24),
		"pickup": _make_tone(700.0, 1200.0, 0.1, "triangle", 0.22),
		"bounce": _make_tone(220.0, 420.0, 0.14, "square", 0.24),
	}

func _make_tone(freq_start: float, freq_end: float, duration: float, wave_type: String, amplitude: float) -> AudioStreamWAV:
	var sample_count: int = max(1, int(SAMPLE_RATE * duration))
	var attack := minf(0.01, duration * 0.2)
	var release := minf(0.05, duration * 0.45)
	var data := PackedByteArray()
	var phase := 0.0
	
	for i in sample_count:
		var t := float(i) / float(sample_count - 1 if sample_count > 1 else 1)
		var freq := lerpf(freq_start, freq_end, t)
		phase += TAU * freq / SAMPLE_RATE
		
		var wave := 0.0
		match wave_type:
			"square":
				wave = 1.0 if sin(phase) >= 0.0 else -1.0
			"triangle":
				wave = asin(sin(phase)) * (2.0 / PI)
			"saw":
				wave = 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
			_:
				wave = sin(phase)
		
		var time := float(i) / SAMPLE_RATE
		var attack_env := minf(1.0, time / attack) if attack > 0.0 else 1.0
		var release_env := minf(1.0, (duration - time) / release) if release > 0.0 else 1.0
		var env := clampf(attack_env * release_env, 0.0, 1.0)
		var sample := clampf(wave * amplitude * env, -1.0, 1.0)
		var value := int(sample * 32767.0)
		
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
