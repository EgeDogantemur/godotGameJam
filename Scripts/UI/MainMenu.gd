extends Control

func _ready() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.in_main_menu = true
	
	$VBoxContainer/PlayBtn.pressed.connect(_on_play_pressed)
	$VBoxContainer/SettingsBtn.pressed.connect(_on_settings_pressed)
	$VBoxContainer/QuitBtn.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.load_game("res://Scenes/emirantestscene.tscn")

func _on_settings_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.show_settings_from_main()

func _on_quit_pressed() -> void:
	var ui_mgr = get_node_or_null("/root/UIManager")
	if ui_mgr: ui_mgr.quit_game()
