extends Control

const BASE_VIEWPORT_SIZE := Vector2(1920.0, 1080.0)

@onready var bgclock: Sprite2D = $Background/Bgclock
@onready var play_btn: Button = $MenuCard/Margin/VBoxContainer/PlayBtn
@onready var settings_btn: Button = $MenuCard/Margin/VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $MenuCard/Margin/VBoxContainer/QuitBtn
@onready var eye_open: Sprite2D = $Goz1
@onready var eye_closed: Sprite2D = $Goz2
@onready var echo_sprite: Sprite2D = $Echo
@onready var runStatsPanel: Control = $MenuCard/Margin/VBoxContainer/RunStatsPanel
@onready var lastTimeValue: Label = $MenuCard/Margin/VBoxContainer/RunStatsPanel/Margin/VBox/LastTimeValue
@onready var bestTimeValue: Label = $MenuCard/Margin/VBoxContainer/RunStatsPanel/Margin/VBox/BestTimeValue

var _eye_tween: Tween
var _is_eye_open := false
var _eye_open_base_position := Vector2.ZERO
var _eye_closed_base_position := Vector2.ZERO
var _echo_base_position := Vector2.ZERO
var _eye_open_rest_scale := Vector2.ONE
var _eye_open_active_scale := Vector2.ONE
var _eye_closed_rest_scale := Vector2.ONE
var _eye_closed_active_scale := Vector2.ONE
var _echo_base_scale := Vector2.ONE

func _play_audio(method_name: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.call(method_name)

func _ready() -> void:
	_cache_responsive_defaults()
	var resize_handler := Callable(self, "_update_responsive_layout")
	var viewport := get_viewport()
	if not viewport.size_changed.is_connected(resize_handler):
		viewport.size_changed.connect(resize_handler)
	_update_responsive_layout()

	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.in_main_menu = true
	_play_audio("play_menu_music")
	
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	play_btn.mouse_entered.connect(func() -> void:
		_set_eye_open(true)
		_play_audio("play_ui_hover")
	)
	play_btn.mouse_exited.connect(func() -> void: _set_eye_open(false))
	play_btn.focus_entered.connect(func() -> void:
		_set_eye_open(true)
		_play_audio("play_ui_hover")
	)
	play_btn.focus_exited.connect(func() -> void: _set_eye_open(false))
	settings_btn.mouse_entered.connect(func() -> void: _play_audio("play_ui_hover"))
	settings_btn.focus_entered.connect(func() -> void: _play_audio("play_ui_hover"))
	quit_btn.mouse_entered.connect(func() -> void: _play_audio("play_ui_hover"))
	quit_btn.focus_entered.connect(func() -> void: _play_audio("play_ui_hover"))
	
	eye_open.modulate.a = 0.0
	eye_closed.modulate.a = 1.0
	_refresh_run_stats()

func _cache_responsive_defaults() -> void:
	_eye_open_base_position = eye_open.position
	_eye_closed_base_position = eye_closed.position
	_echo_base_position = echo_sprite.position
	_eye_open_rest_scale = eye_open.scale
	_eye_open_active_scale = eye_open.scale * 1.05
	_eye_closed_rest_scale = eye_closed.scale
	_eye_closed_active_scale = eye_closed.scale * 0.97
	_echo_base_scale = echo_sprite.scale

func _get_uniform_ui_scale() -> float:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	return min(viewport_size.x / BASE_VIEWPORT_SIZE.x, viewport_size.y / BASE_VIEWPORT_SIZE.y)

func _get_scaled_position(base_position: Vector2, viewport_size: Vector2) -> Vector2:
	return Vector2(
		viewport_size.x * (base_position.x / BASE_VIEWPORT_SIZE.x),
		viewport_size.y * (base_position.y / BASE_VIEWPORT_SIZE.y)
	)

func _fit_bgclock_to_viewport(viewport_size: Vector2) -> void:
	bgclock.position = viewport_size * 0.5
	if bgclock.texture == null:
		return

	var texture_size := bgclock.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var cover_scale: float = max(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	bgclock.scale = Vector2.ONE * cover_scale

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var uniform_scale := _get_uniform_ui_scale()
	_fit_bgclock_to_viewport(viewport_size)
	eye_open.position = _get_scaled_position(_eye_open_base_position, viewport_size)
	eye_closed.position = _get_scaled_position(_eye_closed_base_position, viewport_size)
	echo_sprite.position = _get_scaled_position(_echo_base_position, viewport_size)
	eye_open.scale = (_eye_open_active_scale if _is_eye_open else _eye_open_rest_scale) * uniform_scale
	eye_closed.scale = (_eye_closed_active_scale if _is_eye_open else _eye_closed_rest_scale) * uniform_scale
	echo_sprite.scale = _echo_base_scale * uniform_scale

func _set_eye_open(is_open: bool) -> void:
	_is_eye_open = is_open
	if _eye_tween:
		_eye_tween.kill()
	
	var uniform_scale := _get_uniform_ui_scale()
	var open_scale := (_eye_open_active_scale if is_open else _eye_open_rest_scale) * uniform_scale
	var closed_scale := (_eye_closed_active_scale if is_open else _eye_closed_rest_scale) * uniform_scale

	_eye_tween = create_tween()
	_eye_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_eye_tween.tween_property(eye_open, "modulate:a", 1.0 if is_open else 0.0, 0.2)
	_eye_tween.parallel().tween_property(eye_closed, "modulate:a", 0.0 if is_open else 1.0, 0.2)
	_eye_tween.parallel().tween_property(eye_open, "scale", open_scale, 0.22)
	_eye_tween.parallel().tween_property(eye_closed, "scale", closed_scale, 0.22)

func _on_play_pressed() -> void:
	_play_audio("play_ui_click")
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr:
		ui_mgr.load_intro_cutscene()

func _on_settings_pressed() -> void:
	_play_audio("play_ui_click")
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.show_settings_from_main()

func _on_quit_pressed() -> void:
	_play_audio("play_ui_click")
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.quit_game()

func _refresh_run_stats() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs or not gs.has_completed_runs():
		runStatsPanel.hide()
		return
	
	runStatsPanel.show()
	lastTimeValue.text = gs.format_run_time(gs.last_completed_run_seconds)
	bestTimeValue.text = gs.format_run_time(gs.best_completed_run_seconds)
