extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $GuardSprite
@onready var lantern_sprite: AnimatedSprite2D = $GuardSprite/StickLantern
@onready var state_sprite: AnimatedSprite2D = $GuardSprite/StateSprite
@onready var player: CharacterBody2D = %Player

@export var markers: Array[Marker2D] = []

@export var speed: float = 60.0
@export var deaccelertion: float = 1500.0

@export var marker_change_distance: float = 10.0

@export var suspicious_length: float = 1.0
@export var suspicious_linger_length: float = 3.0

var marker_index: int = 0

var ray_start := Vector2.ZERO
var ray_end := Vector2.ZERO
var is_colliding := false

enum State { PATROL, SUSPICIOUS, ALERT }
var state: State = State.PATROL

enum SuspiciousState { WAITING, MOVING, LOOKING }
var suspicious_state: SuspiciousState = SuspiciousState.WAITING

var player_in_sight := false
var suspicious_time = 0.0
var suspicious_linger_time = 0.0

var last_seen_player := Vector2.ZERO

func _ready() -> void:
	state_sprite.play("none")

func _physics_process(delta: float) -> void:
	var move_dir = Vector2.ZERO
	
	if state == State.PATROL:
		if markers.size() != 0:
			move_dir = markers[marker_index].global_position - global_position
		
			if global_position.distance_to(markers[marker_index].global_position) < marker_change_distance:
				marker_index += 1
				if marker_index == markers.size():
					marker_index = 0
	elif state == State.SUSPICIOUS:
		if suspicious_state == SuspiciousState.WAITING:
			if !player_in_sight:
				suspicious_state = SuspiciousState.MOVING
				sprite.speed_scale = 1.0
				lantern_sprite.speed_scale = 1.0
		else:
			if suspicious_state == SuspiciousState.MOVING:
				move_dir = last_seen_player - global_position
				if global_position.distance_to(last_seen_player) < 5:
					suspicious_state = SuspiciousState.LOOKING
					suspicious_linger_time = suspicious_linger_length
					sprite.speed_scale = 0.0
					sprite.frame = 0
					lantern_sprite.speed_scale = 0.0
					lantern_sprite.frame = 0
			if player_in_sight:
				_change_state(State.SUSPICIOUS)
	elif state == State.ALERT:
		if global_position.distance_to(player.global_position) > 20:
			move_dir = player.global_position - global_position
		else:
			player.velocity = (player.global_position - global_position).normalized() * 400
	
	if move_dir != Vector2.ZERO:
		velocity = speed * move_dir.normalized()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * deaccelertion)
		velocity.y = move_toward(velocity.y, 0, delta * deaccelertion)
	
	move_and_slide()
	_turn_animation()
	
	var old_player_in_sight = player_in_sight
	_look_for_player()
	
	if state == State.PATROL:
		if player_in_sight:
			if !old_player_in_sight:
				if suspicious_linger_time <= 0:
					suspicious_time = 1
					_change_state(State.SUSPICIOUS)
	elif state == State.SUSPICIOUS:
		if player_in_sight:
			suspicious_time -= delta
			
			if suspicious_time <= 0:
				_change_state(State.ALERT)
		else:
			if suspicious_state == SuspiciousState.LOOKING:
				if suspicious_linger_time > 0:
					suspicious_linger_time -= delta
					state_sprite.modulate = Color(1, 1, 1, clamp(suspicious_linger_time, 0, 1))
				else:
					_change_state(State.PATROL)

func _change_state(new_state: State):
	if new_state == State.PATROL:
		state_sprite.play("none")
	elif new_state == State.SUSPICIOUS:
		state_sprite.play("suspicious")
		suspicious_state = SuspiciousState.WAITING
		
		last_seen_player = player.global_position
		velocity = last_seen_player - global_position
		_turn_animation()
		velocity = Vector2.ZERO
		sprite.speed_scale = 0.0
		sprite.frame = 0
		lantern_sprite.speed_scale = 0.0
		lantern_sprite.frame = 0
	elif new_state == State.ALERT:
		state_sprite.play("alert")
	
	if new_state != State.SUSPICIOUS:
		sprite.speed_scale = 1.0
		lantern_sprite.speed_scale = 1.0
	
	state_sprite.modulate = Color(1, 1, 1, 1)
	state = new_state

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
	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(origin, end)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		ray_start = origin
		ray_end = result.position
		is_colliding = result.collider.name == "Player"
	else:
		is_colliding = false
		
	 #and player.light_manager.lights.has($GuardSprite/MainLight)
	if is_colliding and player.in_light:
		player_in_sight = true
		if player.light_manager.in_alert_light:
			_change_state(State.ALERT)
	else:
		player_in_sight = false
	
	queue_redraw()
	
func _draw() -> void:
	if player.light_manager.show_debug_lines:
		var color = Color.BLUE if is_colliding else Color.ORANGE
		
		draw_line(to_local(ray_start), to_local(ray_end), color, 2.0)
		if is_colliding:
			draw_circle(to_local(ray_end), 4.0, Color.GREEN if player_in_sight else Color.YELLOW)
