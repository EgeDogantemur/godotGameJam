extends CanvasLayer

@onready var sync_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/SyncBar
@onready var dash_label: Label = $Control/MarginContainer/VBoxContainer/DashLabel
@onready var restart_panel: Control = $Control/RestartPanel

func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.player_died.connect(_on_player_died)
	restart_panel.hide()
	_update_dash_display(false)
	
	# Connect to player's dash charge signal (deferred so player is ready)
	call_deferred("_connect_player_dash")

func _connect_player_dash() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("dash_charge_changed"):
		player.dash_charge_changed.connect(_update_dash_display)

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

func _update_dash_display(has_charge: bool) -> void:
	if not dash_label: return
	if has_charge:
		dash_label.text = "⚡ DASH READY"
		dash_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		dash_label.text = "DASH: —"
		dash_label.modulate = Color(0.5, 0.5, 0.5, 0.5)
