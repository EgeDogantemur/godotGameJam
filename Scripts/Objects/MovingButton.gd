extends BasePressurePlate
class_name MovingButton

## The button will move between these two markers on the X axis while occupied.
@export var marker_a: Marker2D
@export var marker_b: Marker2D
@export var move_speed: float = 120.0

var _target_marker: Marker2D

func _ready() -> void:
	super._ready()
	_target_marker = marker_b if marker_b else marker_a

func _physics_process(delta: float) -> void:
	if _is_pressed and _target_marker:
		var target_pos = _target_marker.global_position
		# Move only on X axis as requested
		var direction = 1.0 if target_pos.x > global_position.x else -1.0
		
		# Check if we are already close enough to flip
		if abs(global_position.x - target_pos.x) < 5.0:
			_target_marker = marker_a if _target_marker == marker_b else marker_b
		else:
			global_position.x += direction * move_speed * delta
