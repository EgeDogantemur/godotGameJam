extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 220.0
@export var jump_force: float = 520.0
@export var gravity_force: float = 980.0

@export_category("Jump Tuning")
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.10

@export_category("Dash")
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

@export_category("Parry")
@export var parry_window: float = 0.4
@export var parry_launch_force: float = 800.0
@export var parry_cooldown: float = 0.6
@export var parry_freeze_duration: float = 0.12
@export var parry_zoom_amount: float = 0.65
@export var parry_zoom_duration: float = 0.35

var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _was_on_floor: bool = false

var _is_dashing: bool = false
var _dash_cooldown_timer: float = 0.0
var _dash_direction: float = 0.0
var _dash_tween: Tween

var is_parrying: bool = false
var _parry_timer: float = 0.0
var _parry_cooldown_timer: float = 0.0
var _parry_zoom_tween: Tween

var shadow_scene = preload("res://Scenes/Characters/Shadow.tscn")
var shadow_instance: Node2D = null

@onready var trail = $ShadowTrail

func _ready() -> void:
	collision_layer = 1 # Force layer 1 so parry ALWAYS works regardless of editor
	shadow_instance = shadow_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", shadow_instance)
	trail.call_deferred("set_shadow", shadow_instance)

func _physics_process(delta: float) -> void:
	_dash_cooldown_timer -= delta
	_parry_cooldown_timer -= delta
	
	_update_parry(delta)
	
	if _is_dashing:
		velocity.x = _dash_direction * dash_speed
		velocity.y = 0.0
		move_and_slide()
		return
	
	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_movement()
	_try_jump()
	_try_dash()
	move_and_slide()
	_update_animation()

func _update_parry(delta: float) -> void:
	if Input.is_action_just_pressed("evade") and _parry_cooldown_timer <= 0.0:
		is_parrying = true
		_parry_timer = parry_window
		_parry_cooldown_timer = parry_cooldown
		_start_parry_zoom()
	
	if is_parrying:
		_parry_timer -= delta
		if _parry_timer <= 0.0:
			_end_parry_window()

func _start_parry_zoom() -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam: return
	if _parry_zoom_tween:
		_parry_zoom_tween.kill()
	_parry_zoom_tween = create_tween()
	_parry_zoom_tween.tween_property(cam, "zoom", Vector2.ONE * 1.15, 0.1).set_trans(Tween.TRANS_SINE)

func _end_parry_window() -> void:
	is_parrying = false
	var cam = get_viewport().get_camera_2d()
	if cam:
		if _parry_zoom_tween:
			_parry_zoom_tween.kill()
		_parry_zoom_tween = create_tween()
		_parry_zoom_tween.tween_property(cam, "zoom", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)

func execute_parry_launch() -> void:
	is_parrying = false
	_parry_timer = 0.0
	velocity.y = -parry_launch_force
	_coyote_timer = 0.0
	
	_do_hit_freeze()
	_do_success_zoom()
	_do_screen_shake()
	_do_screen_flash()

func _do_hit_freeze() -> void:
	get_tree().paused = true
	var freeze_tween = create_tween()
	freeze_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	freeze_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	freeze_tween.tween_interval(parry_freeze_duration)
	freeze_tween.tween_callback(func(): get_tree().paused = false)

func _do_success_zoom() -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam: return
	if _parry_zoom_tween:
		_parry_zoom_tween.kill()
	
	var punch_zoom = Vector2.ONE * (1.0 / parry_zoom_amount)
	_parry_zoom_tween = create_tween()
	_parry_zoom_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_parry_zoom_tween.tween_property(cam, "zoom", punch_zoom, parry_zoom_duration * 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_parry_zoom_tween.tween_property(cam, "zoom", Vector2.ONE, parry_zoom_duration * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _do_screen_shake() -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam: return
	
	var shake_tw = create_tween()
	shake_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for i in range(5):
		shake_tw.tween_property(cam, "offset", Vector2(randf_range(-12, 12), randf_range(-12, 12)), 0.03)
	shake_tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func _do_screen_flash() -> void:
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 120
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1.0, 1.0, 1.0, 0.8)
	flash_layer.add_child(rect)
	get_tree().current_scene.call_deferred("add_child", flash_layer)
	
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(rect, "color:a", 0.0, 0.2)
	tw.tween_callback(flash_layer.queue_free)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity_force * delta

func _handle_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
	elif is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
	_was_on_floor = is_on_floor()

func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer -= delta

func _handle_movement() -> void:
	var dir = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed

func _try_jump() -> void:
	var can_jump = is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y = -jump_force
		_coyote_timer = 0.0
		_jump_buffer = 0.0

func _try_dash() -> void:
	if not Input.is_action_just_pressed("dash"): return
	if _dash_cooldown_timer > 0.0: return
	
	var dir = Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		var sprite = get_node_or_null("Sprite2D")
		dir = -1.0 if (sprite and sprite.flip_h) else 1.0
	
	_dash_direction = dir
	_is_dashing = true
	_dash_cooldown_timer = dash_cooldown
	
	if _dash_tween:
		_dash_tween.kill()
	
	_dash_tween = create_tween()
	_dash_tween.tween_interval(dash_duration)
	_dash_tween.tween_callback(_end_dash)

func _end_dash() -> void:
	_is_dashing = false
	velocity.x = _dash_direction * speed * 0.5

func _update_animation() -> void:
	var anim = get_node_or_null("AnimationPlayer")
	if not anim: return
	
	if anim.has_animation("jump") and not is_on_floor():
		anim.play("jump" if velocity.y < 0 else "fall")
	elif anim.has_animation("run") and abs(velocity.x) > 10:
		anim.play("run")
	elif anim.has_animation("idle"):
		anim.play("idle")
