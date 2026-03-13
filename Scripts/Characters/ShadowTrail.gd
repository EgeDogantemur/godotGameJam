extends Node

const BUFFER_SYNC = 60
const BUFFER_DESYNC = 180

var _buffer: Array[Dictionary] = []
var _write_idx: int = 0
var _buffer_size: int = BUFFER_SYNC

@onready var player: CharacterBody2D = get_parent()
var shadow_node: Node2D = null

func _ready() -> void:
	_buffer.resize(BUFFER_DESYNC)
	for i in BUFFER_DESYNC:
		_buffer[i] = { "pos": player.global_position, "flip": false }
	
	GameState.state_changed.connect(_on_state_changed)

func set_shadow(node: Node2D) -> void:
	shadow_node = node

func _physics_process(_delta: float) -> void:
	if shadow_node == null: return
	
	var sprite = player.get_node_or_null("Sprite2D")
	_buffer[_write_idx] = {
		"pos": player.global_position,
		"flip": sprite.flip_h if sprite else false
	}
	
	_write_idx = (_write_idx + 1) % BUFFER_DESYNC
	
	var read_idx: int = (_write_idx - _buffer_size + BUFFER_DESYNC) % BUFFER_DESYNC
	var data = _buffer[read_idx]
	
	shadow_node.global_position = data["pos"]
	var shadow_sprite = shadow_node.get_node_or_null("Sprite2D")
	if shadow_sprite:
		shadow_sprite.flip_h = data["flip"]

func _on_state_changed(new_state: GameState.State) -> void:
	match new_state:
		GameState.State.DESYNC:
			_buffer_size = BUFFER_DESYNC
		_:
			_buffer_size = BUFFER_SYNC
