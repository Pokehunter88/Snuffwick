extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $GuardSprite

@export var markers: Array[Marker2D] = []

@export var speed: float = 60.0
@export var deaccelertion: float = 1500.0

@export var marker_change_distance: float = 10.0

var marker_index: int = 0

func _physics_process(delta: float) -> void:
	var move_dir = markers[marker_index].global_position - global_position
	
	if global_position.distance_to(markers[marker_index].global_position) < marker_change_distance:
		marker_index += 1
		if marker_index == markers.size():
			marker_index = 0
	
	if move_dir != Vector2.ZERO:
		velocity = speed * move_dir.normalized()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * deaccelertion)
		velocity.y = move_toward(velocity.y, 0, delta * deaccelertion)
	
	move_and_slide()
	
	_turn_animation()
	#sprite.play("down_idle")
	
func _turn_animation():
	if velocity != Vector2.ZERO:
		if abs(velocity.x) >= abs(velocity.y):
			if velocity.x > 0:
				sprite.play("right_walk")
			else:
				sprite.play("left_walk")
		else:
			if velocity.y > 0:
				sprite.play("down_walk")
			else:
				sprite.play("up_walk")
	else:
		if !sprite.animation.contains("idle"):
			if sprite.animation.contains("right"):
				sprite.play("right_idle")
			if sprite.animation.contains("left"):
				sprite.play("left_idle")
			if sprite.animation.contains("down"):
				sprite.play("down_idle")
			if sprite.animation.contains("up"):
				sprite.play("up_idle")
