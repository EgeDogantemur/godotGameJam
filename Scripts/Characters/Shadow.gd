extends Area2D

@export var spawn_immunity: float = 1.0
var _immunity_timer: float = 0.0

func _ready() -> void:
	_immunity_timer = spawn_immunity
	monitoring = true
	monitorable = true

func _physics_process(delta: float) -> void:
	if _immunity_timer > 0.0:
		_immunity_timer -= delta
		return
	
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if body.is_parrying:
				body.execute_parry_launch()
				return
			else:
				var gs = get_node_or_null("/root/GameState")
				if gs:
					gs.trigger_player_death()
				else:
					get_tree().reload_current_scene()
				return
