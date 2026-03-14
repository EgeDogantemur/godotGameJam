extends Area2D
class_name LevelGoal

@export var next_level_path: String = ""
@export var locked: bool = true

var _is_active: bool = false
var _open_tween: Tween
var _eye_glow_tween: Tween

const LOCKED_GATE_ALPHA := 0.0
const LOCKED_EYE_COLOR := Color(0.8, 1.0, 0.9, 0.95)
const GLOW_EYE_COLOR := Color(1.25, 1.5, 1.3, 1.0)
const UNLOCKED_GATE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const GATE_BASE_SCALE := Vector2(0.4, 0.4)
const GATE_SPAWN_SCALE := Vector2(0.34, 0.34)
const EYE_BASE_SCALE := Vector2(0.075, 0.075)
const EYE_GLOW_SCALE := Vector2(0.09, 0.09)

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.gate_unlocked.connect(unlock)
	
	if locked:
		_set_locked_visual()
	else:
		_is_active = true
		_set_unlocked_visual()

func unlock() -> void:
	if _is_active: return
	_is_active = true
	_play_audio("play_gate_unlock")
	
	if _open_tween:
		_open_tween.kill()
	if _eye_glow_tween:
		_eye_glow_tween.kill()

	var gate_sprite := _get_gate_sprite()
	var eye_sprite := get_node_or_null("Goz1") as Sprite2D
	if not gate_sprite and not eye_sprite:
		return
	
	_open_tween = create_tween()
	if gate_sprite:
		gate_sprite.visible = true
		_open_tween.tween_property(gate_sprite, "modulate", UNLOCKED_GATE_COLOR, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_open_tween.parallel().tween_property(gate_sprite, "scale", GATE_BASE_SCALE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if eye_sprite:
		_open_tween.parallel().tween_property(eye_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_open_tween.parallel().tween_property(eye_sprite, "scale", EYE_BASE_SCALE * 1.1, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_open_tween.tween_callback(func(): eye_sprite.visible = false)

func _set_locked_visual() -> void:
	var gate_sprite := _get_gate_sprite()
	if gate_sprite:
		gate_sprite.visible = true
		gate_sprite.modulate = Color(1.0, 1.0, 1.0, LOCKED_GATE_ALPHA)
		gate_sprite.scale = GATE_SPAWN_SCALE
	var eye_sprite := get_node_or_null("Goz1") as Sprite2D
	if eye_sprite:
		eye_sprite.visible = true
		eye_sprite.modulate = LOCKED_EYE_COLOR
		eye_sprite.scale = EYE_BASE_SCALE
		_start_eye_glow(eye_sprite)

func _set_unlocked_visual() -> void:
	var gate_sprite := _get_gate_sprite()
	if gate_sprite:
		gate_sprite.visible = true
		gate_sprite.modulate = UNLOCKED_GATE_COLOR
		gate_sprite.scale = GATE_BASE_SCALE
	var eye_sprite := get_node_or_null("Goz1") as Sprite2D
	if eye_sprite:
		eye_sprite.visible = false

func _start_eye_glow(eye_sprite: Sprite2D) -> void:
	if _eye_glow_tween:
		_eye_glow_tween.kill()
	
	_eye_glow_tween = create_tween()
	_eye_glow_tween.set_loops()
	_eye_glow_tween.tween_property(eye_sprite, "modulate", GLOW_EYE_COLOR, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eye_glow_tween.parallel().tween_property(eye_sprite, "scale", EYE_GLOW_SCALE, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eye_glow_tween.tween_property(eye_sprite, "modulate", LOCKED_EYE_COLOR, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eye_glow_tween.parallel().tween_property(eye_sprite, "scale", EYE_BASE_SCALE, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if not _is_active: return
	if body.collision_layer & 1 != 0:
		_complete_level()

func _complete_level() -> void:
	if next_level_path != "":
		_play_audio("play_gate_enter")
		get_tree().call_deferred("change_scene_to_file", next_level_path)

func _get_gate_sprite() -> Sprite2D:
	return get_node_or_null("Kapi") as Sprite2D
