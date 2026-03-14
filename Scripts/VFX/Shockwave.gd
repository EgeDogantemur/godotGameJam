extends Node2D

@export var max_radius: float = 250.0
@export var start_thickness: float = 25.0
@export var duration: float = 0.35
@export var shockwave_color: Color = Color(1.2, 1.2, 1.2, 1.0) # Slightly overbright

var _current_radius: float = 10.0
var _current_thickness: float = 10.0
var _current_color: Color = Color.WHITE

func _ready() -> void:
	_current_thickness = start_thickness
	_current_color = shockwave_color
	
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Animate even during hit-freeze
	tw.set_parallel(true)
	
	tw.tween_property(self , "_current_radius", max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self , "_current_thickness", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self , "_current_color:a", 0.0, duration).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _current_thickness > 0.0 and _current_color.a > 0.0:
		draw_arc(Vector2.ZERO, _current_radius, 0.0, TAU, 64, _current_color, _current_thickness, true)
