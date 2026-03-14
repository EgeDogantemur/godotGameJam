extends Area2D

@export var spawn_immunity: float = 1.0
var _immunity_timer: float = 0.0
var _parry_invincibility: float = 0.0
var _coyote_death_timer: float = 0.0
var _override_animation_time: float = 0.0
var _follow_flip: bool = false
var _follow_animation: StringName = &"idle"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_immunity_timer = spawn_immunity
	monitoring = true
	monitorable = true
	add_to_group("hazard")
	if animated_sprite:
		animated_sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	if _override_animation_time > 0.0:
		_override_animation_time = maxf(0.0, _override_animation_time - delta)
		if _override_animation_time <= 0.0:
			_apply_follow_visual_state()
	
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
				play_override_animation(&"parried", 0.45)
				body.execute_parry_launch()
				_parry_invincibility = 0.5
				_coyote_death_timer = 0.0
				return
				
	if player_touching:
		_coyote_death_timer += delta
		if _coyote_death_timer >= 0.1:
			_coyote_death_timer = 0.0
			var gs = get_node_or_null("/root/GameState")
			if gs:
				gs.trigger_player_death()
			else:
				get_tree().reload_current_scene()
	else:
		_coyote_death_timer = 0.0

func apply_follow_visual_state(flip: bool, animation_name: StringName) -> void:
	_follow_flip = flip
	_follow_animation = animation_name
	if _override_animation_time <= 0.0:
		_apply_follow_visual_state()

func play_override_animation(animation_name: StringName, duration: float) -> void:
	_override_animation_time = maxf(_override_animation_time, duration)
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return
	animated_sprite.play(animation_name)

func _apply_follow_visual_state() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var target_animation := _follow_animation
	if not animated_sprite.sprite_frames.has_animation(target_animation):
		target_animation = &"idle"
	
	animated_sprite.flip_h = _follow_flip
	if animated_sprite.animation != target_animation:
		animated_sprite.play(target_animation)
		return
	
	if not animated_sprite.is_playing() and animated_sprite.sprite_frames.get_animation_loop(target_animation):
		animated_sprite.play(target_animation)
