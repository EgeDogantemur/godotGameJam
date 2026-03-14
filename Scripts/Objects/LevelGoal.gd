extends Area2D
class_name LevelGoal

@export var next_level_path: String = ""
@export var locked: bool = true

var _is_active: bool = false
var _open_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.gate_unlocked.connect(unlock)
	
	if locked:
		_set_locked_visual()
	else:
		_is_active = true

func unlock() -> void:
	if _is_active: return
	_is_active = true
	
	if _open_tween:
		_open_tween.kill()

	var gate_sprite := _get_gate_sprite()
	var eye_sprite := get_node_or_null("Goz1") as Sprite2D
	if not gate_sprite and not eye_sprite:
		return
	
	_open_tween = create_tween()
	if gate_sprite:
		_open_tween.tween_property(gate_sprite, "modulate", Color(0.2, 1.0, 0.5, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_open_tween.parallel().tween_property(gate_sprite, "scale", Vector2(0.6, 0.6), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if eye_sprite:
		_open_tween.parallel().tween_property(eye_sprite, "modulate", Color(0.5, 1.0, 0.7, 1.0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_locked_visual() -> void:
	var gate_sprite := _get_gate_sprite()
	if gate_sprite:
		gate_sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
		gate_sprite.scale = Vector2(0.4, 0.4)
	var eye_sprite := get_node_or_null("Goz1") as Sprite2D
	if eye_sprite:
		eye_sprite.modulate = Color(0.5, 0.2, 0.2, 0.7)

func _on_body_entered(body: Node2D) -> void:
	if not _is_active: return
	if body.collision_layer & 1 != 0:
		_complete_level()

func _complete_level() -> void:
	if next_level_path != "":
		get_tree().call_deferred("change_scene_to_file", next_level_path)

func _get_gate_sprite() -> Sprite2D:
	return get_node_or_null("Kapi") as Sprite2D
