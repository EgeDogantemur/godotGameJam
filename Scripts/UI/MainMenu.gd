extends Control

@onready var play_btn: Button = $MenuCard/Margin/VBoxContainer/PlayBtn
@onready var settings_btn: Button = $MenuCard/Margin/VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $MenuCard/Margin/VBoxContainer/QuitBtn
@onready var eye_open: Sprite2D = $Goz1
@onready var eye_closed: Sprite2D = $Goz2

var _eye_tween: Tween

func _ready() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.in_main_menu = true
	
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	play_btn.mouse_entered.connect(func() -> void: _set_eye_open(true))
	play_btn.mouse_exited.connect(func() -> void: _set_eye_open(false))
	play_btn.focus_entered.connect(func() -> void: _set_eye_open(true))
	play_btn.focus_exited.connect(func() -> void: _set_eye_open(false))
	
	eye_open.modulate.a = 0.0
	eye_closed.modulate.a = 1.0

func _set_eye_open(is_open: bool) -> void:
	if _eye_tween:
		_eye_tween.kill()
	
	_eye_tween = create_tween()
	_eye_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_eye_tween.tween_property(eye_open, "modulate:a", 1.0 if is_open else 0.0, 0.2)
	_eye_tween.parallel().tween_property(eye_closed, "modulate:a", 0.0 if is_open else 1.0, 0.2)
	_eye_tween.parallel().tween_property(eye_open, "scale", Vector2.ONE * (0.105 if is_open else 0.1), 0.22)
	_eye_tween.parallel().tween_property(eye_closed, "scale", Vector2.ONE * (0.097 if is_open else 0.1), 0.22)

func _on_play_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.load_game("res://Scenes/emirantestscene.tscn")

func _on_settings_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.show_settings_from_main()

func _on_quit_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.quit_game()
