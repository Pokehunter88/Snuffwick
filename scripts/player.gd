extends CharacterBody2D
class_name Player

#signal died

@onready var player_sprite: AnimatedSprite2D = $PlayerSprite
@onready var shader := $PlayerSprite.material as ShaderMaterial

@export var light_manager: LightManager

@export var in_dark_speed: float = 100.0
@export var in_light_speed: float = 60.0
@export var stagger_speed: float = 10.0
@export var deaccelertion: float = 1500.0

@export var dash_length: float = 0.225
@export var dash_cooldown_length: float = 0.2
@export var dash_speed: float = 500.0
@export var stagger_length: float = 0.5
@export var after_image_fade_speed: float = 1.0

@onready var speed: float = in_dark_speed

var dash_time: float = 0.0
var stagger_time: float = 0.0

var dash_cooldown_time: float = 0.0
var dash_direction := Vector2.ZERO

var in_light := false

var old_move_dir := Vector2.ZERO

func _ready() -> void:
	player_sprite.play("down_idle")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	#shader.set_shader_parameter("light_amount", clamp(((global_position.x - 170) / 50) + 0.5, 0, 1))

func _physics_process(delta: float) -> void:
	var move_dir = Vector2(Input.get_axis("move_left", "move_right"),
	Input.get_axis("move_up", "move_down")) 
	
	# for disabling player movement
	#if light_manager.show_debug_lines:
		#move_dir = Vector2.ZERO
	
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
		
		velocity = dash_direction * dash_speed
		
		_dash_animation()
		
		var after_image = Sprite2D.new()
		
		after_image.texture = player_sprite.sprite_frames.get_frame_texture(player_sprite.animation, player_sprite.frame)
		
		after_image.transform = player_sprite.transform
		after_image.global_position = global_position
		after_image.self_modulate = Color(0.5, 0.5, 0.5, 1.0)
		
		var tween = create_tween()
		tween.tween_property(after_image, "modulate:a", 0.0, 0.5)
		
		tween.tween_callback(after_image.queue_free)
		
		get_tree().current_scene.add_child(after_image)
		
		$DashTrail.emitting = true
	
	if dash_time > 0:
		if velocity == Vector2.ZERO:
			dash_time = 0;
		velocity = dash_direction * dash_speed
		dash_time -= delta
		if dash_time <= 0:
			$DashTrail.emitting = false
			if light_manager.in_light:
				_on_light_manager_player_in_light()
				stagger_time = stagger_length
				player_sprite.speed_scale = stagger_speed / in_dark_speed
			else:
				_on_light_manager_player_in_dark()
			velocity = speed * move_dir.normalized()
			dash_cooldown_time = dash_cooldown_length
	else:
		_turn_animation(false)
	
	if stagger_time > 0:
		speed = stagger_speed
		stagger_time -= delta
		if stagger_time <= 0:
			if light_manager.in_light:
				speed = in_light_speed
				player_sprite.speed_scale = in_light_speed / in_dark_speed
			else:
				speed = in_dark_speed
				player_sprite.speed_scale = 1.0
	
	if dash_cooldown_time > 0:
		dash_cooldown_time -= delta
	
	move_and_slide()
	
	if move_dir != Vector2.ZERO:
		old_move_dir = move_dir

func _dash_animation():
	if player_sprite.animation.contains("right"):
		player_sprite.play("right_dash")
	if player_sprite.animation.contains("left"):
		player_sprite.play("left_dash")
	if player_sprite.animation.contains("down"):
		player_sprite.play("down_dash")
	if player_sprite.animation.contains("up"):
		player_sprite.play("up_dash")

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
		#$PlayerSprite.self_modulate = Color(1, 0, 0)
		shader.set_shader_parameter("light_amount", 1.0)
		shader.set_shader_parameter("squint", true)
		player_sprite.speed_scale = in_light_speed / in_dark_speed
		speed = in_light_speed

func _on_light_manager_player_in_dark() -> void:
	if dash_time <= 0 and in_light:
		in_light = false
		#$PlayerSprite.self_modulate = Color(1, 1, 1)
		shader.set_shader_parameter("light_amount", 0.3)
		shader.set_shader_parameter("squint", false)
		player_sprite.speed_scale = 1.0
		speed = in_dark_speed

#func _on_hitbox_body_entered(body: Node2D) -> void:
	#if body is Enemy:
		#died.emit()
		#queue_free()
