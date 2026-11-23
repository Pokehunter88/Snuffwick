extends PointLight2D
class_name Light

@export var radius: float = 120.0
@export var alert_radius: float = 80.0
@export var is_object: bool = true
@export var can_disable: bool = true

func enable():
	enabled = true
	$ObjectLight.enabled = true
	if is_object:
		get_parent().frame = 0

func disable():
	if can_disable:
		enabled = false
		$ObjectLight.enabled = false
		if is_object:
			if get_parent().hframes > 1:
				get_parent().frame = 1
