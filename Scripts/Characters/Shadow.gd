extends Area2D

@export var spawn_immunity: float = 1.0
var _immunity_timer: float = 0.0
var _parry_invincibility: float = 0.0
var _coyote_death_timer: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_immunity_timer = spawn_immunity
	monitoring = true
	monitorable = true
	add_to_group("hazard")

func _physics_process(delta: float) -> void:
	if _immunity_timer > 0.0:
		_immunity_timer -= delta
		return
		
	if _parry_invincibility > 0.0:
		_parry_invincibility -= delta
		return
		
	var bodies = get_overlapping_bodies()
	var player_touching = false
	
	for body in bodies:
		if body.is_in_group("player"):
			player_touching = true
			if body.current_parry_state == body.ParryState.ACTIVE:
				body.execute_parry_launch()
				_parry_invincibility = 0.5
				_coyote_death_timer = 0.0
				return
				
	if player_touching:
		_coyote_death_timer += delta
		if _coyote_death_timer >= 0.1: # 0.1s Coyote Tolerance
			_coyote_death_timer = 0.0
			var gs = get_node_or_null("/root/GameState")
			if gs:
				gs.trigger_player_death()
			else:
				get_tree().reload_current_scene()
	else:
		_coyote_death_timer = 0.0
