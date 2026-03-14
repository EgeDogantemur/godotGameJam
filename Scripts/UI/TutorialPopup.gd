extends CanvasLayer

@onready var panel = $Control/PanelContainer
@onready var label = $Control/PanelContainer/MarginContainer/Label

var _tween: Tween

func _ready() -> void:
	# Start hidden (off-screen top-left)
	panel.position = Vector2(-500, 40)
	panel.modulate.a = 0.0

func show_message(text: String, duration: float = 0.0) -> void:
	if not is_inside_tree(): return
	
	label.text = text
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Slide in to top-center
	var target_x = (get_viewport().get_visible_rect().size.x / 2.0) - (panel.size.x / 2.0)
	
	_tween.set_parallel(true)
	_tween.tween_property(panel, "position:x", target_x, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	
	# Auto-hide if duration > 0
	if duration > 0.0:
		_tween.set_parallel(false)
		_tween.tween_interval(duration)
		_tween.tween_callback(hide_message)

func hide_message() -> void:
	if not is_inside_tree(): return
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Slide out and fade
	_tween.set_parallel(true)
	_tween.tween_property(panel, "position:y", -100.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_property(panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	_tween.chain().tween_callback(queue_free)
