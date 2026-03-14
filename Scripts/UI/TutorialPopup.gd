extends CanvasLayer

@onready var video_player = $ColorRect/CenterContainer/VBoxContainer/VideoStreamPlayer
@onready var skip_btn = $ColorRect/CenterContainer/VBoxContainer/Button

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Allows UI to process while game is paused
	
	video_player.finished.connect(func(): video_player.play())
	skip_btn.pressed.connect(func() -> void:
		_play_audio("play_ui_click")
		_close_popup()
	)
	
	# Start hidden, fade in
	$ColorRect.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property($ColorRect, "modulate:a", 1.0, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		_play_audio("play_ui_click")
		_close_popup()

func play_video(stream: VideoStream) -> void:
	if not stream:
		_close_popup()
		return
		
	get_tree().paused = true
	video_player.stream = stream
	video_player.play()

func _close_popup() -> void:
	get_tree().paused = false
	queue_free()
