extends Area2D

var _overlap_frames: int = 0
const GRACE_FRAMES: int = 2

var is_frozen: bool = false

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or is_frozen: return
	
	var dist = global_position.distance_to(player.global_position)
	var threshold = 16.0 
	
	if dist < threshold and not Input.is_action_pressed("evade"):
		_overlap_frames += 1
		if _overlap_frames >= GRACE_FRAMES:
			get_tree().reload_current_scene()
	else:
		_overlap_frames = 0

func set_frozen(frozen: bool) -> void:
	if is_frozen == frozen: return
	is_frozen = frozen
	
	var platform = get_node_or_null("PlatformBody")
	var sprite = get_node_or_null("Sprite2D")
	
	if platform:
		platform.collision_layer = 4 if is_frozen else 0
	
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0, 0.8) if is_frozen else Color(1, 1, 1, 0.45)
