extends CanvasLayer

@onready var pause_menu: Control = $PauseMenu
@onready var settings_menu: Control = $SettingsMenu
@onready var sync_bar: ProgressBar = $GameHUD/TopLeft/SyncBar
@onready var dash_label: Label = $GameHUD/TopLeft/DashLabel
@onready var restart_panel: Control = $GameHUD/RestartPanel
@onready var proximity_overlay: ColorRect = $ProximityOverlay
@onready var scanline_overlay: ColorRect = $ScanlineOverlay

var is_paused: bool = false
var in_main_menu: bool = false
var master_bus_idx: int

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.player_died.connect(_on_player_died)
	
	_connect_ui_signals()
	# Connect to player signals deferred to ensure player is in tree
	call_deferred("_connect_player_signals")

func _process(delta: float) -> void:
	if in_main_menu:
		$GameHUD.hide()
		proximity_overlay.hide()
		return
	
	$GameHUD.show()
	proximity_overlay.show()
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		sync_bar.value = (gs.desync_energy / gs.desync_energy_max) * 100.0
		
		# Pulse bar when low
		if sync_bar.value < 25.0:
			sync_bar.modulate = Color(1.0, 0.3, 0.3, 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.01))
		else:
			sync_bar.modulate = Color.WHITE

	_update_proximity_visuals(delta)

func _input(event: InputEvent) -> void:
	if in_main_menu: return
	
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			_close_settings()
		else:
			_toggle_pause()

func _connect_ui_signals() -> void:
	$PauseMenu/VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$PauseMenu/VBox/SettingsBtn.pressed.connect(_on_pause_settings_pressed)
	$PauseMenu/VBox/MainMenuBtn.pressed.connect(_on_main_menu_pressed)
	
	$SettingsMenu/VBox/CloseBtn.pressed.connect(_close_settings)
	$SettingsMenu/VBox/MasterVolSlider.value_changed.connect(_on_master_vol_changed)
	$SettingsMenu/VBox/GlitchSlider.value_changed.connect(_on_scanline_changed)
	
	$GameHUD/RestartPanel/VBox/RestartBtn.pressed.connect(_on_restart_pressed)

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
	restart_panel.show()
	get_tree().paused = true

func _on_restart_pressed() -> void:
	restart_panel.hide()
	get_tree().paused = false
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.reset_for_level()
	get_tree().reload_current_scene()
	# Reconnect signals for the new player instance
	call_deferred("_connect_player_signals")

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_pause_settings_pressed() -> void:
	pause_menu.hide()
	settings_menu.show()

func _close_settings() -> void:
	settings_menu.hide()
	if not in_main_menu:
		pause_menu.show()

func _on_main_menu_pressed() -> void:
	_toggle_pause()
	load_main_menu()

func show_settings_from_main() -> void:
	settings_menu.show()

func load_main_menu() -> void:
	in_main_menu = true
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")

func load_game(level_path: String = "res://Scenes/emirantestscene.tscn") -> void:
	in_main_menu = false
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	get_tree().change_scene_to_file(level_path)

func quit_game() -> void:
	get_tree().quit()

func _on_master_vol_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func _on_scanline_changed(value: float) -> void:
	if scanline_overlay.material:
		scanline_overlay.material.set_shader_parameter("opacity", value * 0.12)
