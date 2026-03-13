extends Area2D

var _overlap_frames: int = 0
const GRACE_FRAMES: int = 2

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	
	var dist = global_position.distance_to(player.global_position)
	var threshold = 16.0 
	
	if dist < threshold:
		_overlap_frames += 1
		if _overlap_frames >= GRACE_FRAMES:
			GameState.player_died.emit()
	else:
		_overlap_frames = 0
