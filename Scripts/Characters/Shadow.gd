extends Area2D

@export var platform_duration: float = 5.0
var platform_timer: float = 0.0

var _overlap_frames: int = 0
const GRACE_FRAMES: int = 2

var is_solid: bool = false

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("evade") and not is_solid:
		_set_solid(true)
		platform_timer = platform_duration
		
	if is_solid:
		platform_timer -= delta
		if platform_timer <= 0.0:
			_set_solid(false)
			
	var player = get_tree().get_first_node_in_group("player")
	if player == null or is_solid: 
		_overlap_frames = 0
		return
	
	# Use overlaps_body instead of distance to properly respect the large CollisionShape2Ds
	if overlaps_body(player):
		_overlap_frames += 1
		if _overlap_frames >= GRACE_FRAMES:
			var game_state = get_node_or_null("/root/GameState")
			if game_state:
				game_state.trigger_player_death()
			else:
				get_tree().reload_current_scene()
	else:
		_overlap_frames = 0

func _set_solid(solid: bool) -> void:
	is_solid = solid
	
	var platform = get_node_or_null("PlatformBody")
	var sprite = get_node_or_null("Sprite2D")
	
	if platform:
		platform.collision_layer = 4 if is_solid else 0
	
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0, 0.8) if is_solid else Color(1, 1, 1, 0.45)
