extends CanvasLayer

@onready var pause_menu: Control = $PauseMenu
@onready var settings_menu: Control = $SettingsMenu
@onready var sync_bar: ProgressBar = $GameHUD/SyncBar
@onready var restart_panel: Control = $GameHUD/RestartPanel

var is_paused: bool = false
var in_main_menu: bool = false

var master_bus_idx: int
var glitch_intensity: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.hide()
	settings_menu.hide()
	restart_panel.hide()
	
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.player_died.connect(_on_player_died)
	
	_connect_signals()

func _process(_delta: float) -> void:
	if in_main_menu:
		$GameHUD.hide()
		return
	
	$GameHUD.show()
	var gs = get_node_or_null("/root/GameState")
	if gs:
		sync_bar.value = (gs.desync_energy / gs.desync_energy_max) * 100.0
		
		if sync_bar.value < 25.0:
			sync_bar.modulate = Color(1.0, 0.3, 0.3, abs(sin(Time.get_ticks_msec() * 0.005)))
		else:
			sync_bar.modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	if in_main_menu: return
	
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			_close_settings()
		else:
			_toggle_pause()

func _connect_signals() -> void:
	$PauseMenu/VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$PauseMenu/VBox/SettingsBtn.pressed.connect(_on_pause_settings_pressed)
	$PauseMenu/VBox/MainMenuBtn.pressed.connect(_on_main_menu_pressed)
	
	$SettingsMenu/VBox/CloseBtn.pressed.connect(_close_settings)
	$SettingsMenu/VBox/MasterVolSlider.value_changed.connect(_on_master_vol_changed)
	$SettingsMenu/VBox/GlitchSlider.value_changed.connect(_on_glitch_changed)
	
	$GameHUD/RestartPanel/VBox/RestartBtn.pressed.connect(_on_restart_pressed)

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

func _on_glitch_changed(value: float) -> void:
	glitch_intensity = value
