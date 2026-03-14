extends Area2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _on_body_entered(body: Node2D) -> void:
	if body.collision_layer & 1 != 0:
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.add_sync_point_energy()
		_play_audio("play_pickup")
		sprite.hide()
		set_deferred("monitoring", false)
		
		if particles:
			particles.emitting = true
			
		if audio and audio.stream:
			audio.play()
			await audio.finished
		else:
			await get_tree().create_timer(1.0).timeout
			
		queue_free()
