extends CharacterBody2D
class_name Player

signal died

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite

@export var light_manager: LightManager

@export var in_dark_speed: float = 100.0
@export var in_light_speed: float = 60.0
@export var deaccelertion: float = 1500.0

@onready var speed: float = in_dark_speed

func _ready() -> void:
	player_sprite.play("down_idle")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
func _physics_process(delta: float) -> void:
	var move_dir = Vector2(Input.get_axis("move_left", "move_right"), 
	Input.get_axis("move_up", "move_down"))
	
	if move_dir != Vector2.ZERO:
		velocity = speed * move_dir.normalized()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * deaccelertion)
		velocity.y = move_toward(velocity.y, 0, delta * deaccelertion)
	
	move_and_slide()
	
	_turn_animation(false)

func _turn_animation(turn: bool):
	if velocity != Vector2.ZERO:
		if abs(velocity.x) >= abs(velocity.y):
			if velocity.x > 0:
				if player_sprite.animation.contains("left"):
					player_sprite.play("turn_right")
				elif !player_sprite.animation.contains("turn")  or turn:
					player_sprite.play("right_walk")
			else:
				if player_sprite.animation.contains("right"):
					player_sprite.play("turn_left")
				elif !player_sprite.animation.contains("turn") or turn:
					player_sprite.play("left_walk")
		else:
			if velocity.y > 0:
				player_sprite.play("down_walk")
			else:
				player_sprite.play("up_walk")
	else:
		if !player_sprite.animation.contains("idle"):
			if player_sprite.animation.contains("right"):
				player_sprite.play("right_idle")
			if player_sprite.animation.contains("left"):
				player_sprite.play("left_idle")
			if player_sprite.animation.contains("down"):
				player_sprite.play("down_idle")
			if player_sprite.animation.contains("up"):
				player_sprite.play("up_idle")

func _on_player_sprite_animation_looped() -> void:
	var finished_animation = player_sprite.animation
	if finished_animation.contains("turn"):
		_turn_animation(true)

func _on_light_manager_player_in_light() -> void:
	$PlayerSprite.self_modulate = Color(1, 0, 0)
	speed = in_light_speed

func _on_light_manager_player_in_dark() -> void:
	$PlayerSprite.self_modulate = Color(1, 1, 1)
	speed = in_dark_speed

#func _on_hitbox_body_entered(body: Node2D) -> void:
	#if body is Enemy:
		#died.emit()
		#queue_free()
