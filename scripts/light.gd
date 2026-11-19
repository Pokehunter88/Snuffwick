extends PointLight2D

@export var radius: float = 10.0

func enable():
	enabled = true
	$ObjectLight.enabled = true
	get_parent().frame = 0

func disable():
	enabled = false
	$ObjectLight.enabled = false
	get_parent().frame = 1
