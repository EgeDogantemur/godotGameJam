extends Area2D

@export var pulse_speed: float = 1.0
@export var pulse_scale: float = 1.05

var _cooldown_timer: float = 0.0

func _ready() -> void:
	# Force correct layers so Editor resets won't break it
	collision_layer = 4
	collision_mask = 1 
	monitoring = true
	add_to_group("hazard")
	
	_start_pulse_animation()

var _coyote_death_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		return
	
	var bodies = get_overlapping_bodies()
	var player_touching = false
	
	for body in bodies:
		if body.is_in_group("player"):
			player_touching = true
			if body.current_parry_state == body.ParryState.ACTIVE:
				# Successful parry!
				body.execute_parry_launch()
				_cooldown_timer = 0.5
				_coyote_death_timer = 0.0
				_do_parry_feedback()
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

func _start_pulse_animation() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	
	var base_scale = sprite.scale
	
	# Create an infinite pulsing Tween relative to base scale
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(sprite, "scale", base_scale * pulse_scale, pulse_speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "scale", base_scale, pulse_speed / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _do_parry_feedback() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0) # Flash white
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_CUBIC)
