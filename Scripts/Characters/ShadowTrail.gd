extends Node

@export var follow_delay_frames: int = 60
var history: Array[Dictionary] = []

@onready var player: CharacterBody2D = get_parent()
var shadow_node: Node2D = null

func _ready() -> void:
	for i in follow_delay_frames:
		history.push_back({ "pos": player.global_position, "flip": false })

func set_shadow(node: Node2D) -> void:
	shadow_node = node

func _physics_process(_delta: float) -> void:
	if shadow_node == null: return
	
	var sprite = player.get_node_or_null("Sprite2D")
	history.push_back({
		"pos": player.global_position,
		"flip": sprite.flip_h if sprite else false
	})
	
	var data: Dictionary = {}
	while history.size() > max(1, follow_delay_frames):
		data = history.pop_front()
		
	if data.is_empty() and history.size() > 0:
		data = history[0]
	
	if not data.is_empty():
		shadow_node.global_position = data["pos"]
		var shadow_sprite = shadow_node.get_node_or_null("Sprite2D")
		if shadow_sprite:
			shadow_sprite.flip_h = data["flip"]
