extends Area2D

@export var bounce_force: float = 520.0
@export var only_bounce_from_above: bool = true
@export var squash_duration: float = 0.12
@export var squash_scale: float = 0.75
@export var stretch_scale: float = 1.15

var _bounce_tween: Tween

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if only_bounce_from_above:
		var push_dir := -global_transform.y
		if body.velocity.dot(push_dir) >= 0:
			return  # Oyuncu zaten fırlatma yönünde; sadece mantara doğru gelince zıplat
	_apply_bounce(body)

func _apply_bounce(player: CharacterBody2D) -> void:
	# Sadece X ekseninde force - mantarın baktığı yönün x bileşeni
	var push_dir := -global_transform.y
	push_dir.y = 0.0
	if push_dir.length_squared() > 0.001:
		player.velocity.x = push_dir.normalized().x * bounce_force
		_play_audio("play_bounce")
	
	# Bouncy squash-stretch hissi
	var sprite = get_node_or_null("Sprite2D")
	if sprite and (_bounce_tween == null or not _bounce_tween.is_valid()):
		var base_scale = sprite.scale
		_bounce_tween = create_tween()
		_bounce_tween.set_trans(Tween.TRANS_BACK)
		_bounce_tween.set_ease(Tween.EASE_OUT)
		_bounce_tween.tween_property(sprite, "scale", base_scale * squash_scale, squash_duration * 0.4)
		_bounce_tween.tween_property(sprite, "scale", base_scale * stretch_scale, squash_duration * 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_bounce_tween.tween_property(sprite, "scale", base_scale, squash_duration * 0.3)
