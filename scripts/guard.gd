extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $GuardSprite
@onready var lantern_sprite: AnimatedSprite2D = $GuardSprite/StickLantern
@onready var state_sprite: AnimatedSprite2D = $GuardSprite/StateSprite
@onready var player: CharacterBody2D = %Player
@onready var shader := $GuardSprite.material as ShaderMaterial

@onready var default_color: Color = $GuardSprite/MainLight.color

@export var markers: Array[Marker2D] = []

@export var chase_speed: float = 80.0
@export var speed: float = 60.0
@export var deaccelertion: float = 1500.0

@export var marker_change_distance: float = 10.0

@export var suspicious_length: float = 1.0
@export var suspicious_linger_length: float = 3.0

@export var alert_color: Color = Color.RED
@export var shadow_energy: float = 2.0
@export var shadow_energy_speed: float = 8.0

var current_color: Color = default_color

var marker_index: int = 0

var ray_start := Vector2.ZERO
var ray_end := Vector2.ZERO
var is_colliding := false

enum State { PATROL, SUSPICIOUS, ALERT, RECOVERING }
var state: State = State.PATROL

enum SuspiciousState { WAITING, MOVING, LOOKING }
var suspicious_state: SuspiciousState = SuspiciousState.WAITING

var player_in_sight := false
var suspicious_time = 0.0
var suspicious_linger_time = 0.0

var last_seen_player := Vector2.ZERO

var can_alert_move := false

func _ready() -> void:
	state_sprite.play("none")
	shader.set_shader_parameter("amount", 0.0)

func _physics_process(delta: float) -> void:
	if !is_instance_valid(player):
		_stop_animation()
		return
	
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
				_start_animation()
		else:
			if suspicious_state == SuspiciousState.MOVING:
				move_dir = last_seen_player - global_position
				if global_position.distance_to(last_seen_player) < 5:
					suspicious_state = SuspiciousState.LOOKING
					suspicious_linger_time = suspicious_linger_length
					_stop_animation()
			if player_in_sight:
				_change_state(State.SUSPICIOUS)
	elif state == State.ALERT and can_alert_move:
		if global_position.distance_to(player.global_position) > 20:
			move_dir = player.global_position - global_position
		else:
			player.take_damage(1)
			player.velocity = (player.global_position - global_position).normalized() * 400
			_change_state(State.RECOVERING)
			get_tree().create_timer(1.5).timeout.connect(func(): _change_state(State.SUSPICIOUS))
			if !is_instance_valid(player):
				return
	
	# For controlling guard
	#move_dir = Vector2(Input.get_axis("move_left", "move_right"),
	#Input.get_axis("move_up", "move_down")) 
	
	if move_dir != Vector2.ZERO:
		velocity = (speed if state != State.ALERT else chase_speed) * move_dir.normalized()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * deaccelertion)
		velocity.y = move_toward(velocity.y, 0, delta * deaccelertion)
	
	move_and_slide()
	_turn_animation()
	
	$GuardSprite/MainLight/PurpleLight.energy = lerp($GuardSprite/MainLight/PurpleLight.energy, shadow_energy, delta * shadow_energy_speed)
	$GuardSprite/MainLight/ShadowLight.energy = $GuardSprite/MainLight/PurpleLight.energy
	
	var old_player_in_sight = player_in_sight
	_look_for_player()
	
	if state == State.PATROL:
		if player_in_sight:
			if !old_player_in_sight:
				if suspicious_linger_time <= 0:
					_change_state(State.SUSPICIOUS)
	elif state == State.SUSPICIOUS:
		if player_in_sight:
			suspicious_time -= delta
			last_seen_player = player.global_position
			
			if suspicious_time <= 0:
				_change_state(State.ALERT)
		else:
			if suspicious_state == SuspiciousState.LOOKING:
				if suspicious_linger_time > 0:
					suspicious_linger_time -= delta
					state_sprite.modulate = Color(1, 1, 1, clamp(suspicious_linger_time, 0, 1))
				else:
					_change_state(State.PATROL)
	elif state == State.RECOVERING and player_in_sight:
		last_seen_player = player.global_position

func _start_animation():
	sprite.speed_scale = 1.0
	lantern_sprite.speed_scale = 1.0
	#print("start")
	
func _stop_animation():
	sprite.speed_scale = 0.0
	sprite.frame = 0
	lantern_sprite.speed_scale = 0.0
	lantern_sprite.frame = 0
	#print("stop")

func _change_state(new_state: State):
	if !is_instance_valid(player):
		return
	
	if new_state == State.PATROL:
		state_sprite.play("none")
		shader.set_shader_parameter("amount", 0.0)
		_start_animation()
	elif new_state == State.SUSPICIOUS:
		state_sprite.play("suspicious")
		suspicious_time = 1
		suspicious_state = SuspiciousState.WAITING
		
		last_seen_player = player.global_position
		velocity = last_seen_player - global_position
		_turn_animation()
		_stop_animation()
		velocity = Vector2.ZERO
		shader.set_shader_parameter("amount", 0.0)
	elif new_state == State.ALERT:
		state_sprite.play("alert")
		
		shader.set_shader_parameter("amount", 1.0)
		
		_stop_animation()
		can_alert_move = false 
		get_tree().create_timer(0.5).timeout.connect(func(): 
			can_alert_move = true 
			_start_animation()
			)
			
		shadow_energy = 0.0
	elif new_state == State.RECOVERING:
		state_sprite.play("none")
		_stop_animation()
	
	if new_state != State.ALERT and new_state != State.RECOVERING:
		shadow_energy = 2.0
	
	state_sprite.modulate = Color(1, 1, 1, 1)
	state = new_state
	Global.GuardState = State.find_key(state)

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
		if player.light_manager.in_alert_light and state != State.ALERT and state != State.RECOVERING:
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
