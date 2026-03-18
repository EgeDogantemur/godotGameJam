extends Node

enum State { SYNC, DESYNC, RESYNC, DEAD }

var current_state: State = State.SYNC
var desync_energy: float = 4.0
var desync_energy_max: float = 4.0
var checkpoint_pos: Vector2 = Vector2.ZERO
var run_time_seconds: float = 0.0
var last_completed_run_seconds: float = -1.0
var best_completed_run_seconds: float = -1.0
var is_run_active: bool = false
var has_completed_run: bool = false

signal state_changed(new_state: State)
signal player_died()
signal resync_flash()
signal gate_unlocked()
signal button_activated(button_name: String)
signal dash_unlocked_changed(is_unlocked: bool)
signal run_time_updated(time_seconds: float)
signal run_completed(final_time_seconds: float, best_time_seconds: float)

var dash_unlocked: bool = false:
	set(v):
		dash_unlocked = v
		dash_unlocked_changed.emit(v)

const ENERGY_DRAIN_RATE = 1.0 / 4.0
const ENERGY_REGEN_RATE = 1.0 / 4.0
const SYNC_POINT_BONUS = 0.50

func _process(delta: float) -> void:
	if is_run_active:
		run_time_seconds += delta
		run_time_updated.emit(run_time_seconds)
	
	match current_state:
		State.DESYNC:
			desync_energy -= ENERGY_DRAIN_RATE * delta * desync_energy_max
			if desync_energy <= 0.0:
				desync_energy = 0.0
				_set_state(State.RESYNC)
		State.SYNC:
			desync_energy = minf(desync_energy + ENERGY_REGEN_RATE * delta * desync_energy_max, desync_energy_max)

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	if new_state == State.RESYNC:
		resync_flash.emit()
		await get_tree().create_timer(0.2).timeout
		_set_state(State.SYNC)

func trigger_player_death() -> void:
	player_died.emit()

func trigger_gate_unlock() -> void:
	gate_unlocked.emit()

func trigger_button(btn_name: String) -> void:
	button_activated.emit(btn_name)

func add_sync_point_energy() -> void:
	desync_energy = minf(desync_energy + desync_energy_max * SYNC_POINT_BONUS, desync_energy_max)

func reset_for_level() -> void:
	desync_energy = desync_energy_max
	current_state = State.SYNC

func start_new_run() -> void:
	run_time_seconds = 0.0
	is_run_active = true
	has_completed_run = false
	run_time_updated.emit(run_time_seconds)

func abandon_run() -> void:
	is_run_active = false
	has_completed_run = false

func complete_run() -> void:
	if not is_run_active:
		return
	
	is_run_active = false
	has_completed_run = true
	last_completed_run_seconds = run_time_seconds
	if best_completed_run_seconds < 0.0 or run_time_seconds < best_completed_run_seconds:
		best_completed_run_seconds = run_time_seconds
	
	run_completed.emit(last_completed_run_seconds, best_completed_run_seconds)

func has_completed_runs() -> bool:
	return last_completed_run_seconds >= 0.0

func format_run_time(time_seconds: float) -> String:
	if time_seconds < 0.0:
		return "--:--.--"
	
	var total_centiseconds := int(round(time_seconds * 100.0))
	var minutes := int(total_centiseconds / 6000.0)
	var seconds := int(total_centiseconds / 100.0) % 60
	var centiseconds := total_centiseconds % 100
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
