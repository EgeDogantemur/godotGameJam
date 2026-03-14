extends Node

enum State { SYNC, DESYNC, RESYNC, DEAD }

var current_state: State = State.SYNC
var desync_energy: float = 4.0
var desync_energy_max: float = 4.0
var checkpoint_pos: Vector2 = Vector2.ZERO

signal state_changed(new_state: State)
signal player_died()
signal resync_flash()
signal gate_unlocked()
signal button_activated(button_name: String)
signal dash_unlocked_changed(is_unlocked: bool)

var dash_unlocked: bool = false:
	set(v):
		dash_unlocked = v
		dash_unlocked_changed.emit(v)

const ENERGY_DRAIN_RATE = 1.0 / 4.0
const ENERGY_REGEN_RATE = 1.0 / 4.0
const SYNC_POINT_BONUS = 0.50

func _process(delta: float) -> void:
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
