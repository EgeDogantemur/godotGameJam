extends Node

const TARGET_DELAY = 60
const CATCHUP_SPEED = 3

var history: Array[Dictionary] = []
var _is_frozen: bool = false

@onready var player: CharacterBody2D = get_parent()
var shadow_node: Node2D = null

func _ready() -> void:
	for i in TARGET_DELAY:
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
	
	if Input.is_action_just_pressed("evade"):
		_is_frozen = not _is_frozen
	
	if _is_frozen:
		if shadow_node.has_method("set_frozen"):
			shadow_node.set_frozen(true)
	else:
		if shadow_node.has_method("set_frozen"):
			shadow_node.set_frozen(false)
			
		var pops = 0
		if history.size() > TARGET_DELAY:
			pops = 1 + mini(CATCHUP_SPEED - 1, history.size() - TARGET_DELAY)
		elif history.size() == TARGET_DELAY:
			pops = 1
			
		var data = null
		for i in range(pops):
			if history.size() > 0:
				data = history.pop_front()
				
		if data != null:
			shadow_node.global_position = data["pos"]
			var shadow_sprite = shadow_node.get_node_or_null("Sprite2D")
			if shadow_sprite:
				shadow_sprite.flip_h = data["flip"]
