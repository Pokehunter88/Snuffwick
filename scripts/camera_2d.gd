extends Camera2D

@export var player: CharacterBody2D
@export var speed: float

var last_position := Vector2.ZERO

func _ready() -> void:
	global_position = player.global_position

func _physics_process(delta: float) -> void:
	var currentPosition
	
	if is_instance_valid(player) :
		currentPosition = player.global_position
	else:
		currentPosition = last_position
	
	global_position = Vector2(
		lerp(global_position.x, currentPosition.x, delta * speed), 
		lerp(global_position.y, currentPosition.y, delta * speed))
	
	last_position = currentPosition
