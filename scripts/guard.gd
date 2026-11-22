extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $GuardSprite
@onready var state_sprite: AnimatedSprite2D = $GuardSprite/StateSprite
@onready var player: CharacterBody2D = %Player

@export var markers: Array[Marker2D] = []

@export var speed: float = 60.0
@export var deaccelertion: float = 1500.0

@export var marker_change_distance: float = 10.0

@export var suspicious_length: float = 0.7
@export var suspicious_linger_length: float = 3.0

var marker_index: int = 0.0

var ray_start := Vector2.ZERO
var ray_end := Vector2.ZERO
var is_colliding := false

var state = 0.0

var player_in_sight := false
var suspicious_time = 0.0
var suspicious_linger_time = 0.0

func _ready() -> void:
	state_sprite.play("none")

func _physics_process(delta: float) -> void:
	var move_dir = Vector2.ZERO
	
	if state == 0:
		if markers.size() != 0:
			move_dir = markers[marker_index].global_position - global_position
		
			if global_position.distance_to(markers[marker_index].global_position) < marker_change_distance:
				marker_index += 1
				if marker_index == markers.size():
					marker_index = 0
	else:
		move_dir = player.global_position - global_position
	
	if move_dir != Vector2.ZERO:
		velocity = speed * move_dir.normalized()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * deaccelertion)
		velocity.y = move_toward(velocity.y, 0, delta * deaccelertion)
	
	move_and_slide()
	_turn_animation()
	
	var old_player_in_sight = player_in_sight
	_look_for_player()
	
	if state == 0:
		if player_in_sight:
			if !old_player_in_sight:
				if suspicious_linger_time <= 0:
					suspicious_time = 1
				else:
					suspicious_time = 0
				state_sprite.play("suspicious")
			suspicious_time -= delta
			
			if suspicious_time <= 0:
				state = 1
				state_sprite.play("alert")
		else:
			if suspicious_time > 0 and old_player_in_sight:
				suspicious_linger_time = suspicious_linger_length
			
			if suspicious_linger_time > 0:
				suspicious_linger_time -= delta
			else:
				state_sprite.play("none")

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

func _look_for_player():
	var origin = global_position
	var end = player.global_position
	
	#if origin.distance_to(end) < interact_distance:
		#_check_interact(light_source)
	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(origin, end)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		ray_start = origin
		ray_end = result.position
		is_colliding = result.collider.name == "Player"
	else:
		is_colliding = false
	
	if is_colliding and player.in_light:
		player_in_sight = true
	else:
		player_in_sight = false
	
	queue_redraw()
	
func _draw() -> void:
	if player.light_manager.show_debug_lines:
		var color = Color.BLUE if is_colliding else Color.ORANGE
		
		draw_line(to_local(ray_start), to_local(ray_end), color, 2.0)
		if is_colliding:
			draw_circle(to_local(ray_end), 4.0, Color.GREEN if player_in_sight else Color.YELLOW)
