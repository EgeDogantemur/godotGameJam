extends Area2D
class_name LevelGoal

@export var next_level_path: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.collision_layer & 1 != 0: # Checks if layer 1 (Player)
		_complete_level()

func _complete_level() -> void:
	# Add transition logic here later if needed (e.g. fade out)
	print("Level Complete! Loading: ", next_level_path)
	if next_level_path != "":
		get_tree().call_deferred("change_scene_to_file", next_level_path)
	else:
		print("No next level assigned.")
