extends CharacterBody2D

const SPEED = 220.0
const JUMP_FORCE = -520.0
const GRAVITY = 980.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER = 0.10

var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _was_on_floor: bool = false
var shadow_scene = preload("res://Scenes/Characters/Shadow.tscn")
var shadow_instance: Node2D = null

@onready var trail = $ShadowTrail

func _ready() -> void:
	shadow_instance = shadow_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", shadow_instance)
	trail.call_deferred("set_shadow", shadow_instance)
	GameState.state_changed.connect(_on_state_changed)
	GameState.resync_flash.connect(_on_resync_flash)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_jump_buffer(delta)
	_handle_desync_input()
	_handle_movement()
	_try_jump()
	move_and_slide()
	_update_animation()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor():
		_coyote_timer = COYOTE_TIME
	elif is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta
	_was_on_floor = is_on_floor()

func _handle_desync_input() -> void:
	var pressing = Input.is_action_pressed("desync")
	match GameState.current_state:
		GameState.State.SYNC:
			if pressing and GameState.desync_energy > 0.0:
				GameState._set_state(GameState.State.DESYNC)
		GameState.State.DESYNC:
			if not pressing:
				GameState._set_state(GameState.State.RESYNC)

func _handle_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer -= delta

func _handle_movement() -> void:
	var dir = Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED

func _try_jump() -> void:
	var can_jump = is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer > 0.0 and can_jump:
		velocity.y = JUMP_FORCE
		_coyote_timer = 0.0
		_jump_buffer = 0.0

func _update_animation() -> void:
	var anim = get_node_or_null("AnimationPlayer")
	if not anim: return
	
	if anim.has_animation("jump") and not is_on_floor():
		anim.play("jump" if velocity.y < 0 else "fall")
	elif anim.has_animation("run") and abs(velocity.x) > 10:
		anim.play("run")
	elif anim.has_animation("idle"):
		anim.play("idle")

func _on_state_changed(_new_state: GameState.State) -> void:
	pass

func _on_resync_flash() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.05)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)
