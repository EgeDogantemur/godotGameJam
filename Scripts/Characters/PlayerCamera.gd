extends Camera2D

@export_category("Distance / Framing")
@export var camera_zoom: Vector2 = Vector2.ONE
@export var base_offset: Vector2 = Vector2.ZERO
@export var additional_offset: Vector2 = Vector2.ZERO

@export_category("Smoothing (Softness)")
@export var smooth_speed: float = 8.0
@export var enable_look_ahead: bool = true

@export_category("Look Ahead (Dynamic Targeting)")
@export var look_ahead_x: float = 120.0
@export var look_ahead_y: float = 80.0
@export var look_speed: float = 2.5
@export var jump_look_threshold: float = -300.0
@export var fall_look_threshold: float = 300.0
@export var upward_look_multiplier: float = 0.5
@export var use_facing_direction_when_idle: bool = true

var _target_offset: Vector2 = Vector2.ZERO
@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	# Enable Godot's built-in sub-pixel position smoothing
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	zoom = camera_zoom
	offset = base_offset + additional_offset
	# Ensure this camera is the active one
	make_current()

func _physics_process(delta: float) -> void:
	if not enable_look_ahead or not player:
		offset = offset.lerp(base_offset + additional_offset, look_speed * delta)
		return
		
	var target_x: float = 0.0
	var target_y: float = 0.0
	
	# Horizontal Look Ahead: Shift camera towards movement direction
	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		target_x = dir * look_ahead_x
	elif use_facing_direction_when_idle:
		# If standing still, default to the direction character is facing
		var sprite = player.get_node_or_null("AnimatedSprite2D")
		if sprite:
			target_x = -look_ahead_x if sprite.flip_h else look_ahead_x
			
	# Vertical Look Ahead: Shift camera down when falling fast
	if player.velocity.y > fall_look_threshold:
		target_y = look_ahead_y
	elif player.velocity.y < jump_look_threshold:
		target_y = -look_ahead_y * upward_look_multiplier # Shift up slightly when jumping
		
	# Smoothly interpolate the camera's offset to the target offset
	_target_offset = base_offset + additional_offset + Vector2(target_x, target_y)
	offset = offset.lerp(_target_offset, look_speed * delta)
