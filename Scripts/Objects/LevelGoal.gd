extends Area2D
class_name LevelGoal

@export var next_level_path: String = ""
@export var locked: bool = true

var _is_active: bool = false
var _open_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if locked:
		_set_locked_visual()
	else:
		_is_active = true

func unlock() -> void:
	_is_active = true
	
	if _open_tween:
		_open_tween.kill()
	
	_open_tween = create_tween()
	
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		_open_tween.tween_property(sprite, "modulate", Color(0.2, 1.0, 0.5, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_open_tween.parallel().tween_property(sprite, "scale", Vector2(0.6, 0.6), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func lock() -> void:
	_is_active = false
	
	if _open_tween:
		_open_tween.kill()
	
	_open_tween = create_tween()
	
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		_open_tween.tween_property(sprite, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3).set_trans(Tween.TRANS_SINE)
		_open_tween.parallel().tween_property(sprite, "scale", Vector2(0.4, 0.4), 0.3).set_trans(Tween.TRANS_SINE)

func _set_locked_visual() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
		sprite.scale = Vector2(0.4, 0.4)

func _on_body_entered(body: Node2D) -> void:
	if not _is_active: return
	if body.collision_layer & 1 != 0:
		_complete_level()

func _complete_level() -> void:
	if next_level_path != "":
		get_tree().call_deferred("change_scene_to_file", next_level_path)
