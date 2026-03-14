extends AnimatableBody2D
class_name MovingPlatform

## The platform will move between these two markers on the X axis while active.
@export var marker_a: Marker2D
@export var marker_b: Marker2D
@export var move_speed: float = 120.0
@export var return_to_start: bool = false

var is_active: bool = false
var _target_marker: Marker2D

func _ready() -> void:
	_target_marker = marker_b if marker_b else marker_a

func _physics_process(delta: float) -> void:
	if is_active and _target_marker:
		var target_x = _target_marker.global_position.x
		global_position.x = move_toward(global_position.x, target_x, move_speed * delta)
		
		if is_equal_approx(global_position.x, target_x):
			var next_marker = _get_next_marker(_target_marker)
			if next_marker:
				_target_marker = next_marker
	elif not is_active and return_to_start and marker_a:
		# Return to marker_a if not active.
		global_position.x = move_toward(global_position.x, marker_a.global_position.x, move_speed * delta)
		_target_marker = marker_b if marker_b else marker_a

func _get_next_marker(current_marker: Marker2D) -> Marker2D:
	if marker_a and marker_b:
		return marker_a if current_marker == marker_b else marker_b
	return current_marker
