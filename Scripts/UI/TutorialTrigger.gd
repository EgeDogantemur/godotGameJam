extends Area2D

@export_multiline var tutorial_text: String = "You can jump instead of die"
@export var show_once: bool = false
@export var display_duration: float = 0.0 # 0.0 means it stays until player exits the area

var popup_scene = preload("res://Scenes/UI/TutorialPopup.tscn")
var _current_popup: Node = null
var _has_shown: bool = false

func _ready() -> void:
	collision_mask = 1 # Player layer
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if show_once and _has_shown: return
	
	_has_shown = true
	
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.queue_free()
		
	_current_popup = popup_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", _current_popup)
	
	# Wait one frame for it to enter the tree, then show message
	await get_tree().process_frame
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.show_message(tutorial_text, display_duration)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.hide_message()
		_current_popup = null
