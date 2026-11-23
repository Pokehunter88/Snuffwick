extends Node2D
class_name LightManager

signal player_in_light
signal player_in_dark

@onready var light_sources := get_tree().get_nodes_in_group("light_sources")

@export var interact_distance: float = 30.0

var show_debug_lines := false

var ray_start := []
var ray_end := []
var is_colliding := []

var in_light := false
var in_alert_light := false
var lights: Array[Light] = []

func _process(_delta: float) -> void:
	var currently_in_light := false
	
	ray_start = []
	ray_end = []
	is_colliding = []
	in_alert_light = false
	
	lights = []
	for light_source in light_sources:
		var origin = light_source.global_position
		var end = global_position
		
		var distance = origin.distance_to(end)
		
		if distance > light_source.radius or !light_source.enabled or !light_source.is_visible_in_tree():
			continue
		
		if distance < interact_distance:
			_check_interact(light_source)
		
		var space_state = get_world_2d().direct_space_state
		ray_start.append(origin)
		
		var query = PhysicsRayQueryParameters2D.create(origin, end)
		query.hit_from_inside = true
		
		var result = space_state.intersect_ray(query)
		if result:
			ray_end.append(result.position)
			currently_in_light = currently_in_light or result.collider.name == "Player"
			lights.append(light_source)
			is_colliding.append(result.collider.name == "Player")
			
			in_alert_light = in_alert_light or distance < light_source.alert_radius
		else:
			ray_end.append(end)
			is_colliding.append(false)
	
	if currently_in_light and !in_light:
		player_in_light.emit()
	elif !currently_in_light and in_light:
		player_in_dark.emit()
	
	in_light = currently_in_light
	
	if Input.is_action_just_pressed("debug"):
		show_debug_lines = !show_debug_lines
		queue_redraw()
	if show_debug_lines:
		queue_redraw()

func _check_interact(light_source: PointLight2D):
	if Input.is_action_just_pressed("interact"):
		light_source.disable()

func _draw() -> void:
	if show_debug_lines:
		for i in ray_start.size():
			var local_start = to_local(ray_start[i])
			var local_end = to_local(ray_end[i])
			var color = Color.GREEN if is_colliding[i] else Color.RED
			
			draw_line(local_start, local_end, color, 2.0)
			if is_colliding[i]:
				draw_circle(local_end, 4.0, Color.YELLOW)
