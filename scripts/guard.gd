extends AnimatedSprite2D

@export var simplification_epsilon: float = 2.0

func _ready() -> void:
	generate_occluder()
	play("right_walk")

func generate_occluder() -> void:
	if not sprite_frames.get_frame_texture(animation, frame):
		return

	# 1. Create a BitMap from the sprite's alpha channel
	var image: Image = sprite_frames.get_frame_texture(animation, frame).get_image()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)

	# 2. Convert opaque pixels into polygon outlines
	var rect := Rect2(Vector2.ZERO, bitmap.get_size())
	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(rect, simplification_epsilon)

	# 3. Create a LightOccluder2D for each generated polygon island
	for poly in polygons:
		# Offset points if the sprite is centered
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

func _on_frame_changed() -> void:
	generate_occluder()
	
	if animation != $StickLantern.animation:
		$StickLantern.play(animation)
	$StickLantern.set_frame_and_progress(frame, 0)
