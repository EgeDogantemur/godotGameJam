extends Area2D
class_name BasePressurePlate

enum AcceptedType { BOTH, PLAYER_ONLY, SHADOW_ONLY }

@export var accepted_type: AcceptedType = AcceptedType.BOTH
@export var target_platform: NodePath

var _is_pressed: bool = false
var _occupants: int = 0

signal button_pressed()
signal button_released()

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	match accepted_type:
		AcceptedType.BOTH:
			collision_mask = 1 | 2 
		AcceptedType.PLAYER_ONLY:
			collision_mask = 1 
		AcceptedType.SHADOW_ONLY:
			collision_mask = 2 

func _on_body_entered(body: Node2D) -> void:
	if _is_valid_occupant(body):
		_add_occupant()

func _on_body_exited(body: Node2D) -> void:
	if _is_valid_occupant(body):
		_remove_occupant()

func _on_area_entered(area: Area2D) -> void:
	if _is_valid_occupant(area):
		_add_occupant()

func _on_area_exited(area: Area2D) -> void:
	if _is_valid_occupant(area):
		_remove_occupant()

func _is_valid_occupant(node: Node2D) -> bool:
	if accepted_type == AcceptedType.BOTH:
		return node.collision_layer & 1 != 0 or node.collision_layer & 2 != 0
	elif accepted_type == AcceptedType.PLAYER_ONLY:
		return node.collision_layer & 1 != 0
	elif accepted_type == AcceptedType.SHADOW_ONLY:
		return node.collision_layer & 2 != 0
	return false

func _add_occupant() -> void:
	_occupants += 1
	if _occupants == 1 and not _is_pressed:
		_is_pressed = true
		$Sprite2D.modulate = Color(0.5, 1.0, 0.5)
		_play_audio("play_button_press")
		button_pressed.emit()
		
		var gs = get_node_or_null("/root/GameState")
		var plat = get_node_or_null(target_platform)
		
		if plat and "is_active" in plat:
			plat.is_active = true
		elif gs:
			# Only trigger gate if this button is NOT a platform trigger
			gs.trigger_gate_unlock()
			
		if gs:
			gs.trigger_button(name)

func _remove_occupant() -> void:
	_occupants -= 1
	if _occupants <= 0 and _is_pressed:
		_occupants = 0
		_is_pressed = false
		$Sprite2D.modulate = Color(1.0, 1.0, 1.0)
		_play_audio("play_button_release")
		button_released.emit()
		
		var plat = get_node_or_null(target_platform)
		if plat and "is_active" in plat:
			plat.is_active = false
