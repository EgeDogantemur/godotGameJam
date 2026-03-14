extends Area2D

@export var tutorial_video: VideoStream
@export var show_once: bool = true

var popup_scene = preload("res://Scenes/UI/TutorialPopup.tscn")
var _current_popup: Node = null

# Static vars persist across quick-reloads (deaths) within the same Godot Engine session!
static var global_triggered_videos: Dictionary = {}

func _ready() -> void:
	collision_mask = 1 # Player layer
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if not tutorial_video: return
	
	# Generate unique ID based on Level path and Trigger node name
	var scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else "unknown"
	var key = scene_path + "_" + name
	
	if show_once and global_triggered_videos.has(key): return
	global_triggered_videos[key] = true
	
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.queue_free()
		
	_current_popup = popup_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", _current_popup)
	
	await get_tree().process_frame
	if _current_popup and is_instance_valid(_current_popup):
		_current_popup.play_video(tutorial_video)
