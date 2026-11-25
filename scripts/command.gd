extends CanvasLayer

func _ready() -> void:
	Global.Command = self

func _process(delta: float) -> void:
	$Control/Label.text = Global.GuardState
