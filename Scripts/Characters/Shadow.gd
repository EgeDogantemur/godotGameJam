extends Area2D

@export var platform_duration: float = 5.0
@export var spawn_immunity: float = 1.0
var platform_timer: float = 0.0
var _immunity_timer: float = 0.0

var is_solid: bool = false
var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_immunity_timer = spawn_immunity

func _physics_process(delta: float) -> void:
	if _immunity_timer > 0.0:
		_immunity_timer -= delta
		return
		
	if Input.is_action_just_pressed("evade") and not is_solid:
		_set_solid(true)
		platform_timer = platform_duration
		
	if is_solid:
		platform_timer -= delta
		if platform_timer <= 0.0:
			_set_solid(false)
			
	if _player_inside and not is_solid:
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			game_state.trigger_player_death()
		else:
			get_tree().reload_current_scene()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _set_solid(solid: bool) -> void:
	is_solid = solid
	
	var platform = get_node_or_null("PlatformBody")
	var sprite = get_node_or_null("Sprite2D")
	
	if platform:
		platform.collision_layer = 4 if is_solid else 0
	
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0, 0.8) if is_solid else Color(1, 1, 1, 0.45)
