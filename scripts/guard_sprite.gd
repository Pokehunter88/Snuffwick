extends AnimatedSprite2D

@export var simplification_epsilon: float = 2.0
@export var light_speed: float = 100.0

var light_position := Vector2.ZERO

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

		var occluder_node := $LightOccluder2D
		occluder_node.occluder = occluder_poly

func _process(_delta: float) -> void:
	#$MainLight.position = $MainLight.position.lerp(light_position, delta * light_speed)
	$MainLight.position = light_position

func _on_frame_changed() -> void:
	generate_occluder()
	
	if animation != $StickLantern.animation:
		$StickLantern.play(animation)
	$StickLantern.set_frame_and_progress(frame, 0)
	
	if FRAME_OFFSETS.has(animation):
		light_position = FRAME_OFFSETS[animation]

func _on_animation_changed() -> void:
	_on_frame_changed()
