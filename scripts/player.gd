extends CharacterBody2D
class_name Player

signal died

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite

@export var light_manager: LightManager

@export var in_dark_speed: float = 100.0
@export var in_light_speed: float = 60.0
@export var deaccelertion: float = 1500.0

@export var dash_length: float = 0.15
@export var dash_cooldown_length: float = 0.2
@export var dash_speed: float = 500.0
@export var after_image_fade_speed: float = 1.0

@onready var speed: float = in_dark_speed

var dash_time: float = 0.0
var dash_cooldown_time: float = 0.0
var dash_direction := Vector2.ZERO

var in_light := false

var old_move_dir := Vector2.ZERO

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
	
	if Input.is_action_just_pressed("dash") and !light_manager.in_light and dash_time <= 0 and dash_cooldown_time <= 0:
		dash_time = dash_length
		if move_dir != Vector2.ZERO:
			dash_direction = move_dir.normalized()
		else:
			dash_direction = old_move_dir.normalized()
		var after_image = Sprite2D.new()
		
		after_image.texture = player_sprite.sprite_frames.get_frame_texture(player_sprite.animation, player_sprite.frame)
		
		after_image.transform = player_sprite.transform
		after_image.global_position = global_position
		after_image.self_modulate = Color(0.5, 0.5, 0.5, 1.0)
		
		var tween = create_tween()
		tween.tween_property(after_image, "modulate:a", 0.0, 0.5)
		
		tween.tween_callback(after_image.queue_free)
		
		get_tree().current_scene.add_child(after_image)
	
	if dash_time > 0:
		velocity = dash_direction * dash_speed
		dash_time -= delta
		if dash_time <= 0:
			if light_manager.in_light:
				_on_light_manager_player_in_light()
			else:
				_on_light_manager_player_in_dark()
			velocity = speed * move_dir.normalized()
			dash_cooldown_time = dash_cooldown_length
	
	if dash_cooldown_time > 0:
		dash_cooldown_time -= delta
	
	move_and_slide()
	
	_turn_animation(false)
	
	if move_dir != Vector2.ZERO:
		old_move_dir = move_dir

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
	if dash_time <= 0 and !in_light:
		in_light = true
		$PlayerSprite.self_modulate = Color(1, 0, 0)
		speed = in_light_speed

func _on_light_manager_player_in_dark() -> void:
	if dash_time <= 0 and in_light:
		in_light = false
		$PlayerSprite.self_modulate = Color(1, 1, 1)
		speed = in_dark_speed

#func _on_hitbox_body_entered(body: Node2D) -> void:
	#if body is Enemy:
		#died.emit()
		#queue_free()
