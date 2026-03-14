extends Node

@export_category("Configuration")
@export var follow_delay_frames: int = 60
@export var shadow_follow_smoothness: float = 0.1
@export var catchup_speed: float = 3.0

var history: Array[Dictionary] = []

var fractional_index: float = 0.0
var _consumption_rate: float = 1.0
var _current_target_speed: float = 1.0
var _speed_tween: Tween
var _pos_tween: Tween

@onready var player: CharacterBody2D = get_parent()
var shadow_node: Node2D = null

func _ready() -> void:
	for i in follow_delay_frames:
		history.push_back({ "pos": player.global_position, "flip": false })

func set_shadow(node: Node2D) -> void:
	shadow_node = node

func _set_target_speed(spd: float) -> void:
	if _current_target_speed == spd:
		return
	_current_target_speed = spd
	
	if _speed_tween:
		_speed_tween.kill()
		
	_speed_tween = create_tween()
	_speed_tween.tween_property(self, "_consumption_rate", spd, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _physics_process(delta: float) -> void:
	if shadow_node == null: return
	
	var sprite = player.get_node_or_null("Sprite2D")
	history.push_back({
		"pos": player.global_position,
		"flip": sprite.flip_h if sprite else false
	})
	
	var target_size = max(1, follow_delay_frames)
	var data: Dictionary = {}
	
	if player.get("is_parrying"):
		_set_target_speed(0.15)
	elif history.size() > target_size + 5:
		_set_target_speed(catchup_speed)
	else:
		_set_target_speed(1.0)
		
	fractional_index += _consumption_rate
	var pop_count = floor(fractional_index)
	
	if history.size() - pop_count < target_size and _consumption_rate > 1.0:
		pop_count = max(0, history.size() - target_size)
		fractional_index = 0.0
	else:
		fractional_index -= pop_count
		
	for i in range(pop_count):
		if history.size() > 1:
			data = history.pop_front()
		
	if data.is_empty() and history.size() > 0:
		data = history[0]
	
	if not data.is_empty():
		if _pos_tween:
			_pos_tween.kill()
			
		_pos_tween = create_tween()
		_pos_tween.tween_property(shadow_node, "global_position", data["pos"], shadow_follow_smoothness).set_trans(Tween.TRANS_LINEAR)
		
		var shadow_sprite = shadow_node.get_node_or_null("Sprite2D")
		if shadow_sprite:
			shadow_sprite.flip_h = data["flip"]
