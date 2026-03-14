extends Area2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Detect player layer
	monitoring = true
	monitorable = false
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.trigger_player_death()
		else:
			get_tree().reload_current_scene()
