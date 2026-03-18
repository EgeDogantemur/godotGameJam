extends ColorRect

signal close_requested

@onready var status_label: Label = $Card/Margin/VBox/Status
@onready var name_input: LineEdit = $Card/Margin/VBox/ProfilePanel/Margin/VBox/NameInput
@onready var save_name_btn: Button = $Card/Margin/VBox/Actions/SaveNameBtn
@onready var submit_btn: Button = $Card/Margin/VBox/Actions/SubmitRunBtn
@onready var refresh_btn: Button = $Card/Margin/VBox/Actions/RefreshBtn
@onready var close_btn: Button = $Card/Margin/VBox/Actions/CloseBtn
@onready var entries_text: RichTextLabel = $Card/Margin/VBox/ScoresPanel/Margin/VBox/EntriesText
@onready var pending_hint: Label = $Card/Margin/VBox/PendingHint

func _ready() -> void:
	hide()
	save_name_btn.pressed.connect(_on_save_name_pressed)
	submit_btn.pressed.connect(_on_submit_pressed)
	refresh_btn.pressed.connect(_on_refresh_pressed)
	close_btn.pressed.connect(func() -> void: close_requested.emit())
	name_input.text_submitted.connect(func(_text: String) -> void: _on_save_name_pressed())
	_refresh_state()

func open_overlay() -> void:
	show()
	_refresh_state()
	call_deferred("_refresh_entries_deferred")

func close_overlay() -> void:
	hide()

func _refresh_entries_deferred() -> void:
	await _refresh_entries()

func _get_leaderboard_manager() -> Node:
	return get_node_or_null("/root/LeaderboardManager")

func _refresh_state(status_override: String = "") -> void:
	var leaderboard_manager := _get_leaderboard_manager()
	if leaderboard_manager == null:
		status_label.text = "Leaderboard manager bulunamadi."
		submit_btn.disabled = true
		refresh_btn.disabled = true
		save_name_btn.disabled = true
		pending_hint.text = ""
		entries_text.text = "Leaderboard kullanilamiyor."
		return

	name_input.text = str(leaderboard_manager.get("player_name"))
	var has_pending: bool = bool(leaderboard_manager.call("has_pending_submission"))
	submit_btn.disabled = not has_pending
	refresh_btn.disabled = false
	save_name_btn.disabled = false

	if has_pending:
		var pending_time_text: String = str(leaderboard_manager.call("get_pending_time_text"))
		pending_hint.text = "Hazir gonderim: %s" % pending_time_text
	else:
		pending_hint.text = "Son tamamlanan kosu geldiginde buradan gonderebilirsin."

	if not status_override.is_empty():
		status_label.text = status_override
	else:
		status_label.text = str(leaderboard_manager.call("get_status_summary"))

func _refresh_entries() -> void:
	var leaderboard_manager := _get_leaderboard_manager()
	if leaderboard_manager == null:
		return

	_refresh_state("Leaderboard yukleniyor...")
	var result: Variant = await leaderboard_manager.call("refresh_scores")
	if result is Dictionary:
		var result_dict: Dictionary = result
		var entries: Array = []
		if result_dict.has("entries") and result_dict["entries"] is Array:
			entries = result_dict["entries"]
		entries_text.text = _build_entries_text(entries)
		_refresh_state(str(result_dict.get("message", "")))
	else:
		entries_text.text = "Skorlar alinamadi."
		_refresh_state("Skorlar alinamadi.")

func _build_entries_text(entries: Array) -> String:
	if entries.is_empty():
		return "Henuz gonderilmis bir sure yok.\nIlk sirayi almak icin ilk kosuyu sen gonder."

	var lines: Array[String] = []
	for entry in entries:
		if entry is Dictionary:
			var entry_dict: Dictionary = entry
			var rank: int = int(entry_dict.get("rank", 0))
			var player: String = str(entry_dict.get("player_name", "ANON"))
			var time_text: String = str(entry_dict.get("time_text", "--:--.--"))
			lines.append("%d. %s - %s" % [rank, player, time_text])
	return "\n".join(lines)

func _on_save_name_pressed() -> void:
	var leaderboard_manager := _get_leaderboard_manager()
	if leaderboard_manager == null:
		return

	var result: Variant = leaderboard_manager.call("set_player_name", name_input.text)
	if result is Dictionary:
		var result_dict: Dictionary = result
		_refresh_state(str(result_dict.get("message", "")))
		if bool(result_dict.get("ok", false)) and bool(leaderboard_manager.call("has_pending_submission")):
			var submit_result: Variant = await leaderboard_manager.call("submit_pending_run")
			if submit_result is Dictionary:
				var submit_dict: Dictionary = submit_result
				_refresh_state(str(submit_dict.get("message", "")))
				await _refresh_entries()

func _on_submit_pressed() -> void:
	var leaderboard_manager := _get_leaderboard_manager()
	if leaderboard_manager == null:
		return

	var result: Variant = await leaderboard_manager.call("submit_pending_run")
	if result is Dictionary:
		var result_dict: Dictionary = result
		_refresh_state(str(result_dict.get("message", "")))
		if bool(result_dict.get("ok", false)):
			await _refresh_entries()

func _on_refresh_pressed() -> void:
	await _refresh_entries()
