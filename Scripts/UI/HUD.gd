extends CanvasLayer

@onready var sync_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/SyncBar
@onready var restart_panel: Control = $Control/RestartPanel

func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.player_died.connect(_on_player_died)
	restart_panel.hide()

func _process(_delta: float) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		sync_bar.value = (game_state.desync_energy / game_state.desync_energy_max) * 100.0
	
	if sync_bar.value < 25.0:
		sync_bar.modulate = Color(1.0, 0.3, 0.3, abs(sin(Time.get_ticks_msec() * 0.005)))
	else:
		sync_bar.modulate = Color.WHITE

func _on_player_died() -> void:
	restart_panel.show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.desync_energy = game_state.desync_energy_max
	get_tree().reload_current_scene()
