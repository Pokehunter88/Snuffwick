extends PointLight2D

@export var radius: float = 10.0
@export var is_object: bool = true

func enable():
	enabled = true
	$ObjectLight.enabled = true
	if is_object:
		get_parent().frame = 0

func disable():
	enabled = false
	$ObjectLight.enabled = false
	if is_object:
		if get_parent().hframes > 1:
			get_parent().frame = 1
