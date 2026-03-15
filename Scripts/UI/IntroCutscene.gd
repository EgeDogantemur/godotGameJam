extends CanvasLayer

@export_file("*.tscn") var next_level_path: String = "res://Scenes/1 Level.tscn"
@export var allow_skip: bool = true

@onready var video_player: VideoStreamPlayer = $ColorRect/CenterContainer/VBoxContainer/VideoStreamPlayer
@onready var skip_btn: Button = $ColorRect/CenterContainer/VBoxContainer/SkipButton
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr:
		ui_mgr.in_main_menu = true
	
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.stop_music()
	
	skip_btn.visible = allow_skip
	skip_btn.pressed.connect(_on_skip_pressed)
	video_player.finished.connect(_on_video_finished)
	
	if not video_player.stream:
		_go_to_level()
		return
	
	await get_tree().process_frame
	video_player.play()
	if audio_player.stream:
		audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if not allow_skip or _is_transitioning:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_to_level()

func _on_video_finished() -> void:
	_go_to_level()

func _on_skip_pressed() -> void:
	_go_to_level()

func _go_to_level() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	if audio_player.playing:
		audio_player.stop()
	if video_player.is_playing():
		video_player.stop()
	
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr:
		ui_mgr.load_game(next_level_path, true)
		return
	
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.stop_music()
	get_tree().change_scene_to_file(next_level_path)
