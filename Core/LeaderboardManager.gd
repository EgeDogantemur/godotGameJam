extends Node

const LeaderboardConfig = preload("res://Core/LeaderboardConfig.gd")
const PROFILE_PATH := "user://leaderboard_profile.cfg"
const MAX_ENCODED_SCORE := 35999999

signal profile_updated(player_name: String)
signal pending_run_changed(has_pending: bool, time_seconds: float)

var player_name: String = ""
var pending_time_seconds: float = -1.0
var _configured: bool = false

func _ready() -> void:
	_load_profile()
	_configure_service()

	var game_state := get_node_or_null("/root/GameState")
	if game_state and not game_state.run_completed.is_connected(_on_run_completed):
		game_state.run_completed.connect(_on_run_completed)

func has_pending_submission() -> bool:
	return pending_time_seconds >= 0.0

func get_pending_time_text() -> String:
	return _format_time(pending_time_seconds)

func get_status_summary() -> String:
	if _get_silentwolf_root() == null:
		return "Online leaderboard eklentisi kurulu degil."
	if not _has_credentials():
		return "Leaderboard API bilgileri eksik."
	if not _configured:
		return "Leaderboard servisi henuz hazir degil."
	return "Online leaderboard hazir."

func is_available() -> bool:
	return _configured and _get_scores_service() != null

func set_player_name(new_name: String) -> Dictionary:
	var cleaned_name: String = new_name.strip_edges()
	if cleaned_name.length() < 3:
		return {"ok": false, "message": "Kullanici adi en az 3 karakter olmali."}
	if cleaned_name.length() > 16:
		cleaned_name = cleaned_name.substr(0, 16)

	player_name = cleaned_name
	_save_profile()
	profile_updated.emit(player_name)
	return {"ok": true, "message": "Kullanici adi kaydedildi."}

func refresh_scores(limit: int = LeaderboardConfig.MAX_ENTRIES) -> Dictionary:
	var entries: Array = []
	if not is_available():
		return {"ok": false, "message": get_status_summary(), "entries": entries}

	var scores_service := _get_scores_service()
	if scores_service == null:
		return {"ok": false, "message": "Leaderboard servisi bulunamadi.", "entries": entries}

	var request: Object = null
	if scores_service.has_method("get_scores"):
		request = scores_service.call("get_scores") as Object
	elif scores_service.has_method("get_high_scores"):
		request = scores_service.call("get_high_scores", limit) as Object
	else:
		return {"ok": false, "message": "Skor cekme methodu bulunamadi.", "entries": entries}

	var payload: Variant = await _await_scores_response(request, scores_service)
	var raw_scores: Array = _extract_scores(payload, scores_service)
	entries = _normalize_scores(raw_scores, limit)

	if entries.is_empty():
		return {"ok": true, "message": "Heniz skor gonderilmemis.", "entries": entries}
	return {"ok": true, "message": "En hizli kosular yuklendi.", "entries": entries}

func submit_pending_run() -> Dictionary:
	if not has_pending_submission():
		return {"ok": false, "message": "Gonderilecek sure yok."}
	return await submit_time(pending_time_seconds)

func submit_time(time_seconds: float) -> Dictionary:
	if time_seconds < 0.0:
		return {"ok": false, "message": "Gecersiz sure."}

	if player_name.is_empty():
		pending_time_seconds = time_seconds
		pending_run_changed.emit(true, pending_time_seconds)
		return {
			"ok": false,
			"needs_name": true,
			"message": "Skor gondermek icin once kullanici adi gir."
		}

	if not is_available():
		pending_time_seconds = time_seconds
		pending_run_changed.emit(true, pending_time_seconds)
		return {"ok": false, "message": get_status_summary()}

	var scores_service := _get_scores_service()
	if scores_service == null:
		return {"ok": false, "message": "Leaderboard servisi bulunamadi."}

	var encoded_score: int = _encode_time(time_seconds)
	var request: Object = null
	if scores_service.has_method("save_score"):
		request = scores_service.call("save_score", player_name, encoded_score) as Object
	elif scores_service.has_method("persist_score"):
		request = scores_service.call("persist_score", player_name, encoded_score) as Object
	else:
		return {"ok": false, "message": "Skor gonderme methodu bulunamadi."}

	var payload: Variant = await _await_save_response(request, scores_service)
	if payload is Dictionary:
		var payload_dict: Dictionary = payload
		if payload_dict.has("success") and not bool(payload_dict["success"]):
			var error_message: String = str(payload_dict.get("error", "Skor gonderilemedi."))
			return {"ok": false, "message": error_message}

	pending_time_seconds = -1.0
	pending_run_changed.emit(false, pending_time_seconds)
	return {"ok": true, "message": "Sure leaderboard'a gonderildi."}

func _on_run_completed(final_time_seconds: float, _best_time_seconds: float) -> void:
	pending_time_seconds = final_time_seconds
	pending_run_changed.emit(true, pending_time_seconds)
	if not player_name.is_empty() and is_available():
		call_deferred("_submit_pending_run_deferred")

func _submit_pending_run_deferred() -> void:
	await submit_pending_run()

func _get_silentwolf_root() -> Node:
	return get_node_or_null("/root/SilentWolf")

func _get_scores_service() -> Object:
	var silentwolf_root := _get_silentwolf_root()
	if silentwolf_root == null:
		return null

	var scores_service: Object = null
	if silentwolf_root.has_node("Scores"):
		scores_service = silentwolf_root.get_node("Scores")
	elif silentwolf_root.get("Scores") != null:
		scores_service = silentwolf_root.get("Scores") as Object
	return scores_service

func _has_credentials() -> bool:
	return not LeaderboardConfig.API_KEY.is_empty() and not LeaderboardConfig.GAME_ID.is_empty()

func _configure_service() -> void:
	var silentwolf_root := _get_silentwolf_root()
	if silentwolf_root == null or not _has_credentials():
		_configured = false
		return

	if silentwolf_root.has_method("configure"):
		silentwolf_root.call("configure", {
			"api_key": LeaderboardConfig.API_KEY,
			"game_id": LeaderboardConfig.GAME_ID,
			"game_version": LeaderboardConfig.GAME_VERSION,
			"log_level": LeaderboardConfig.LOG_LEVEL
		})
	_configured = true

func _load_profile() -> void:
	var config := ConfigFile.new()
	var err: int = config.load(PROFILE_PATH)
	if err != OK:
		player_name = ""
		return

	var stored_name: String = str(config.get_value("profile", "player_name", ""))
	player_name = stored_name.strip_edges()

func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "player_name", player_name)
	config.save(PROFILE_PATH)

func _await_scores_response(request: Object, fallback_target: Object) -> Variant:
	if request != null:
		if request.has_signal("sw_get_scores_complete"):
			return await request.sw_get_scores_complete
		if request.has_signal("sw_scores_received"):
			await request.sw_scores_received
			return null

	if fallback_target != null:
		if fallback_target.has_signal("sw_get_scores_complete"):
			return await fallback_target.sw_get_scores_complete
		if fallback_target.has_signal("sw_scores_received"):
			await fallback_target.sw_scores_received
			return null

	return null

func _await_save_response(request: Object, fallback_target: Object) -> Variant:
	if request != null:
		if request.has_signal("sw_save_score_complete"):
			return await request.sw_save_score_complete
		if request.has_signal("sw_score_posted"):
			return await request.sw_score_posted

	if fallback_target != null:
		if fallback_target.has_signal("sw_save_score_complete"):
			return await fallback_target.sw_save_score_complete
		if fallback_target.has_signal("sw_score_posted"):
			return await fallback_target.sw_score_posted

	return null

func _extract_scores(payload: Variant, scores_service: Object) -> Array:
	if payload is Dictionary:
		var payload_dict: Dictionary = payload
		if payload_dict.has("scores") and payload_dict["scores"] is Array:
			return payload_dict["scores"]
		if payload_dict.has("result") and payload_dict["result"] is Dictionary:
			var result_dict: Dictionary = payload_dict["result"]
			if result_dict.has("scores") and result_dict["scores"] is Array:
				return result_dict["scores"]

	if scores_service != null:
		var cached_scores: Variant = scores_service.get("scores")
		if cached_scores is Array:
			return cached_scores

	return []

func _normalize_scores(raw_scores: Array, limit: int) -> Array:
	var entries: Array = []
	var rank: int = 1

	for raw_entry in raw_scores:
		if rank > limit:
			break
		if raw_entry is Dictionary:
			var entry_dict: Dictionary = raw_entry
			var listed_name: String = str(entry_dict.get("player_name", entry_dict.get("name", "ANON")))
			var score_value: int = int(entry_dict.get("score", 0))
			var time_seconds: float = _decode_time(score_value)
			entries.append({
				"rank": rank,
				"player_name": listed_name,
				"score": score_value,
				"time_seconds": time_seconds,
				"time_text": _format_time(time_seconds)
			})
			rank += 1

	return entries

func _encode_time(time_seconds: float) -> int:
	var centiseconds: int = int(round(time_seconds * 100.0))
	return maxi(0, MAX_ENCODED_SCORE - centiseconds)

func _decode_time(score_value: int) -> float:
	var centiseconds_left: int = maxi(0, MAX_ENCODED_SCORE - score_value)
	return float(centiseconds_left) / 100.0

func _format_time(time_seconds: float) -> String:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("format_run_time"):
		return str(game_state.call("format_run_time", time_seconds))

	if time_seconds < 0.0:
		return "--:--.--"

	var total_centiseconds: int = int(round(time_seconds * 100.0))
	var minutes: int = int(total_centiseconds / 6000.0)
	var seconds: int = int(total_centiseconds / 100.0) % 60
	var centiseconds: int = total_centiseconds % 100
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
