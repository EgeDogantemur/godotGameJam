extends Area2D

@export_category("Breathing")
@export var breath_speed: float = 2.5
@export var breath_scale_min: float = 0.92
@export var breath_scale_max: float = 1.08

@export_category("Parry Feedback")
@export var parry_rotation_degrees: float = 360.0
@export var parry_rotation_duration: float = 0.25
@export var parry_flash_modulate: Color = Color(2.0, 2.0, 2.0, 1.0)

var _cooldown_timer: float = 0.0
var _breath_tween: Tween

func _get_sprite() -> Node2D:
	var s = get_node_or_null("Sprite2D")
	if s: return s
	s = get_node_or_null("Diken1(1)")
	if s: return s
	for c in get_children():
		if c is Sprite2D:
			return c
	return null

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 
	monitoring = true
	add_to_group("hazard")
	
	_start_breathing()

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

func _start_breathing() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	
	var base_scale = sprite.scale
	var scale_min = base_scale * breath_scale_min
	var scale_max = base_scale * breath_scale_max
	
	if _breath_tween:
		_breath_tween.kill()
	
	# Soft nefes alma hissi - min -> max -> min (nefes al, nefes ver)
	sprite.scale = scale_min
	_breath_tween = create_tween()
	_breath_tween.set_loops()
	_breath_tween.set_trans(Tween.TRANS_SINE)
	_breath_tween.set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(sprite, "scale", scale_max, breath_speed * 0.5)
	_breath_tween.tween_property(sprite, "scale", scale_min, breath_speed * 0.5)

func _do_parry_feedback() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	
	# Flash
	sprite.modulate = parry_flash_modulate
	var flash_tw = create_tween()
	flash_tw.tween_property(sprite, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_CUBIC)
	
	# Anlık rotasyon - kendi etrafında dönüş, sonra normale dön
	var start_rot = sprite.rotation
	var rot_tw = create_tween()
	rot_tw.set_trans(Tween.TRANS_BACK)
	rot_tw.set_ease(Tween.EASE_OUT)
	rot_tw.tween_property(sprite, "rotation", start_rot + deg_to_rad(parry_rotation_degrees), parry_rotation_duration * 0.5)
	rot_tw.tween_property(sprite, "rotation", start_rot, parry_rotation_duration * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
