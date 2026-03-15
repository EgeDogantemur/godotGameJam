extends CanvasLayer

@onready var pause_menu: Control = $PauseMenu
@onready var pause_eye_open: Sprite2D = $PauseMenu/Goz1
@onready var pause_eye_closed: Sprite2D = $PauseMenu/Goz2
@onready var settings_menu: Control = $SettingsMenu
@onready var settings_eye_open: Sprite2D = $SettingsMenu/Goz1
@onready var settings_eye_closed: Sprite2D = $SettingsMenu/Goz2
@onready var dash_label: Label = $GameHUD/TopLeft/DashLabel
@onready var restart_panel: Control = $GameHUD/RestartPanel
@onready var restart_card: Control = $GameHUD/RestartPanel/Card
@onready var restart_title: Label = $GameHUD/RestartPanel/Card/Margin/VBox/Title
@onready var proximity_overlay: ColorRect = $ProximityOverlay
@onready var scanline_overlay: ColorRect = $ScanlineOverlay

var is_paused: bool = false
var in_main_menu: bool = false
var master_bus_idx: int
var _restart_tween: Tween
var _pause_eye_tween: Tween
var _settings_eye_tween: Tween

func _play_audio(method_name: String, args: Array = []) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.callv(method_name, args)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	pause_eye_open.modulate.a = 0.0
	pause_eye_closed.modulate.a = 1.0
	settings_eye_open.modulate.a = 0.0
	settings_eye_closed.modulate.a = 1.0
	
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.player_died.connect(_on_player_died)
		gs.dash_unlocked_changed.connect(_on_dash_unlocked_changed)
		
		# Auto-unlock dash if we are at or beyond level 6
		var path = get_tree().current_scene.scene_file_path
		var level_num = path.get_file().to_int()
		if level_num >= 6:
			gs.dash_unlocked = true
			
		dash_label.visible = gs.dash_unlocked
	
	_connect_ui_signals()
	# Connect to player signals deferred to ensure player is in tree
	call_deferred("_connect_player_signals")

func _on_dash_unlocked_changed(is_unlocked: bool) -> void:
	dash_label.visible = is_unlocked

func _process(delta: float) -> void:
	if in_main_menu:
		$GameHUD.hide()
		proximity_overlay.hide()
		return
	
	$GameHUD.show()
	proximity_overlay.show()
	
	_update_proximity_visuals(delta)

func _input(event: InputEvent) -> void:
	if in_main_menu: return
	if restart_panel.visible:
		if event.is_action_pressed("jump"):
			_restart_level()
			get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			_close_settings()
		else:
			_toggle_pause()

func _connect_ui_signals() -> void:
	var resume_btn: Button = $PauseMenu/Card/Margin/VBox/ResumeBtn
	var settings_btn: Button = $PauseMenu/Card/Margin/VBox/SettingsBtn
	var main_menu_btn: Button = $PauseMenu/Card/Margin/VBox/MainMenuBtn
	
	resume_btn.pressed.connect(_on_resume_pressed)
	settings_btn.pressed.connect(_on_pause_settings_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	
	for btn in [resume_btn, settings_btn, main_menu_btn]:
		btn.mouse_entered.connect(func() -> void:
			_play_audio("play_ui_hover")
			_refresh_pause_eye_state()
		)
		btn.mouse_exited.connect(_refresh_pause_eye_state)
		btn.focus_entered.connect(func() -> void:
			_play_audio("play_ui_hover")
			_refresh_pause_eye_state()
		)
		btn.focus_exited.connect(_refresh_pause_eye_state)
	
	var close_btn: Button = $SettingsMenu/Card/Margin/VBox/CloseBtn
	var master_slider: HSlider = $SettingsMenu/Card/Margin/VBox/MasterPanel/Margin/VBox/MasterVolSlider
	var glitch_slider: HSlider = $SettingsMenu/Card/Margin/VBox/GlitchPanel/Margin/VBox/GlitchSlider
	
	close_btn.pressed.connect(_close_settings)
	master_slider.value_changed.connect(_on_master_vol_changed)
	glitch_slider.value_changed.connect(_on_scanline_changed)
	
	for control in [close_btn, master_slider, glitch_slider]:
		control.mouse_entered.connect(func() -> void:
			_play_audio("play_ui_hover")
			_refresh_settings_eye_state()
		)
		control.mouse_exited.connect(_refresh_settings_eye_state)
		control.focus_entered.connect(func() -> void:
			_play_audio("play_ui_hover")
			_refresh_settings_eye_state()
		)
		control.focus_exited.connect(_refresh_settings_eye_state)
	
	$GameHUD/RestartPanel/Card/Margin/VBox/RestartBtn.pressed.connect(_on_restart_pressed)

func _connect_player_signals() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("dash_charge_changed"):
			player.dash_charge_changed.connect(_update_dash_display)
		# Initial state
		if "_has_dash_charge" in player:
			_update_dash_display(player._has_dash_charge)

func _update_proximity_visuals(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Detect closest hazard distance for the shader
	# We use a 0.0 to 1.0 range where 1.0 is danger
	var max_dist = 250.0 # Distance where warning starts
	var min_dist = 40.0  # Distance where warning is max
	var closest_dist = max_dist
	
	var hazards = get_tree().get_nodes_in_group("hazard")
	for h in hazards:
		if is_instance_valid(h):
			var d = player.global_position.distance_to(h.global_position)
			if d < closest_dist:
				closest_dist = d
	
	var prox_factor = 1.0 - clamp((closest_dist - min_dist) / (max_dist - min_dist), 0.0, 1.0)
	
	# Update shader uniform
	if proximity_overlay.material:
		proximity_overlay.material.set_shader_parameter("proximity", prox_factor)

func _update_dash_display(has_charge: bool) -> void:
	if has_charge:
		dash_label.text = "⚡ DASH READY"
		dash_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		dash_label.text = "DASH: —"
		dash_label.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _on_player_died() -> void:
	is_paused = false
	pause_menu.hide()
	settings_menu.hide()
	_show_restart_panel()
	_play_audio("play_death")
	get_tree().paused = true

func _on_restart_pressed() -> void:
	_play_audio("play_ui_click")
	_restart_level()

func _restart_level() -> void:
	restart_panel.hide()
	get_tree().paused = false
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.reset_for_level()
	get_tree().reload_current_scene()
	# Reconnect signals for the new player instance
	call_deferred("_connect_player_signals")

func _show_restart_panel() -> void:
	restart_panel.show()
	restart_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	restart_card.scale = Vector2(0.94, 0.94)
	restart_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
	restart_title.modulate = Color(1.3, 0.2, 0.2, 0.0)
	
	if _restart_tween:
		_restart_tween.kill()
	
	_restart_tween = create_tween()
	_restart_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_restart_tween.tween_property(restart_panel, "modulate:a", 1.0, 0.18)
	_restart_tween.parallel().tween_property(restart_card, "modulate:a", 1.0, 0.2)
	_restart_tween.parallel().tween_property(restart_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_restart_tween.parallel().tween_property(restart_title, "modulate:a", 1.0, 0.16)
	_restart_tween.parallel().tween_property(restart_title, "scale", Vector2.ONE * 1.02, 0.08).from(Vector2.ONE * 0.96)

func _refresh_pause_eye_state() -> void:
	call_deferred("_update_pause_eye_state")

func _update_pause_eye_state() -> void:
	var should_open := false
	for path in [
		"PauseMenu/Card/Margin/VBox/ResumeBtn",
		"PauseMenu/Card/Margin/VBox/SettingsBtn",
		"PauseMenu/Card/Margin/VBox/MainMenuBtn"
	]:
		var btn := get_node_or_null(path) as Button
		if btn and (btn.is_hovered() or btn.has_focus()):
			should_open = true
			break
	_set_pause_eye_open(should_open)

func _set_pause_eye_open(is_open: bool) -> void:
	if _pause_eye_tween:
		_pause_eye_tween.kill()
	
	_pause_eye_tween = create_tween()
	_pause_eye_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pause_eye_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pause_eye_tween.tween_property(pause_eye_open, "modulate:a", 1.0 if is_open else 0.0, 0.2)
	_pause_eye_tween.parallel().tween_property(pause_eye_closed, "modulate:a", 0.0 if is_open else 1.0, 0.2)
	_pause_eye_tween.parallel().tween_property(pause_eye_open, "scale", Vector2.ONE * (0.105 if is_open else 0.1), 0.22)
	_pause_eye_tween.parallel().tween_property(pause_eye_closed, "scale", Vector2.ONE * (0.097 if is_open else 0.1), 0.22)

func _refresh_settings_eye_state() -> void:
	call_deferred("_update_settings_eye_state")

func _update_settings_eye_state() -> void:
	var should_open := false
	for path in [
		"SettingsMenu/Card/Margin/VBox/MasterPanel/Margin/VBox/MasterVolSlider",
		"SettingsMenu/Card/Margin/VBox/GlitchPanel/Margin/VBox/GlitchSlider",
		"SettingsMenu/Card/Margin/VBox/CloseBtn"
	]:
		var control := get_node_or_null(path) as Control
		if control and (control.has_focus() or control.get_global_rect().has_point(get_viewport().get_mouse_position())):
			should_open = true
			break
	_set_settings_eye_open(should_open)

func _set_settings_eye_open(is_open: bool) -> void:
	if _settings_eye_tween:
		_settings_eye_tween.kill()
	
	_settings_eye_tween = create_tween()
	_settings_eye_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_settings_eye_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_settings_eye_tween.tween_property(settings_eye_open, "modulate:a", 1.0 if is_open else 0.0, 0.2)
	_settings_eye_tween.parallel().tween_property(settings_eye_closed, "modulate:a", 0.0 if is_open else 1.0, 0.2)
	_settings_eye_tween.parallel().tween_property(settings_eye_open, "scale", Vector2.ONE * (0.105 if is_open else 0.1), 0.22)
	_settings_eye_tween.parallel().tween_property(settings_eye_closed, "scale", Vector2.ONE * (0.097 if is_open else 0.1), 0.22)

func _toggle_pause() -> void:
	is_paused = not is_paused
	_play_audio("play_pause_toggle", [is_paused])
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	if not is_paused:
		_set_pause_eye_open(false)

func _on_resume_pressed() -> void:
	_play_audio("play_ui_click")
	_toggle_pause()

func _on_pause_settings_pressed() -> void:
	_play_audio("play_ui_click")
	pause_menu.hide()
	settings_menu.show()
	_set_pause_eye_open(false)
	_set_settings_eye_open(false)

func _close_settings() -> void:
	_play_audio("play_ui_click")
	settings_menu.hide()
	_set_settings_eye_open(false)
	if not in_main_menu:
		pause_menu.show()

func _on_main_menu_pressed() -> void:
	_play_audio("play_ui_click")
	_toggle_pause()
	load_main_menu()

func show_settings_from_main() -> void:
	settings_menu.show()
	_set_settings_eye_open(false)

func load_main_menu() -> void:
	in_main_menu = true
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	_play_audio("stop_music")
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func load_intro_cutscene(cutscene_path: String = "res://Scenes/UI/IntroCutscene.tscn") -> void:
	in_main_menu = true
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	_play_audio("stop_music")
	get_tree().change_scene_to_file(cutscene_path)

func load_game(level_path: String = "res://Scenes/emirantestscene.tscn", play_music: bool = true) -> void:
	in_main_menu = false
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	_play_audio("stop_music")
	get_tree().change_scene_to_file(level_path)
	if play_music:
		call_deferred("_start_game_music_after_scene_change")

func _start_game_music_after_scene_change() -> void:
	await get_tree().process_frame
	_play_audio("play_game_music")

func quit_game() -> void:
	get_tree().quit()

func _on_master_vol_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func _on_scanline_changed(value: float) -> void:
	if scanline_overlay.material:
		scanline_overlay.material.set_shader_parameter("opacity", value * 0.12)
