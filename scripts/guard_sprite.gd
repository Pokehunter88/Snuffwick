extends AnimatedSprite2D

@export var simplification_epsilon: float = 2.0
@export var light_speed: float = 50.0

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO

var time: float = 0.0

var start_animation := ""
var old_animation := ""

const FRAME_OFFSETS := {
	"up_walk": Vector2(-6.0, -12.0),
	"down_walk": Vector2(7.0, 20.0),
	"left_walk": Vector2(-15.0, 6.0),
	"right_walk": Vector2(15.0, 6.0)
}

func _ready() -> void:
	generate_occluder()
	_on_frame_changed()

func generate_occluder() -> void:
	if not sprite_frames.get_frame_texture(animation, frame):
		return

	var image: Image = sprite_frames.get_frame_texture(animation, frame).get_image()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)

	var rect := Rect2(Vector2.ZERO, bitmap.get_size())
	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(rect, simplification_epsilon)

	for poly in polygons:
		if centered:
			var offset_poly := PackedVector2Array()
			var half_size := Vector2(bitmap.get_size()) / 2.0
			for point in poly:
				offset_poly.append(point - half_size)
			poly = offset_poly

		var occluder_poly := OccluderPolygon2D.new()
		occluder_poly.polygon = poly
		occluder_poly.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
		

		var occluder_node := $LightOccluder2D
		occluder_node.occluder = occluder_poly

func _process(delta: float) -> void:
	if time > 0:
		time -= delta * 5.0
		
		var target = start_position + ((end_position - start_position) * (1 - time))
		
		if (start_animation == "up_walk" and animation == "right_walk") or (
			start_animation == "right_walk" and animation == "up_walk"):
			target.y -= sin(time * PI) * 9.0
		elif (start_animation == "left_walk" and animation == "right_walk") or (
			start_animation == "right_walk" and animation == "left_walk"):
			target.y += sin(time * PI) * 9.0
		elif (start_animation == "up_walk" and animation == "down_walk") or (
			start_animation == "down_walk" and animation == "up_walk"):
			target.x -= sin(time * PI) * 13.0
		
		$MainLight.position = target

func _on_frame_changed() -> void:
	generate_occluder()
	
	if animation != $StickLantern.animation:
		$StickLantern.play(animation)
	$StickLantern.set_frame_and_progress(frame, 0)
	
	if FRAME_OFFSETS.has(animation) and animation != old_animation:
		start_position = $MainLight.position
		end_position = FRAME_OFFSETS[animation]
		time = 1.0
		start_animation = old_animation
	
	old_animation = animation

func _on_animation_changed() -> void:
	_on_frame_changed()
