extends Node

var Player : CharacterBody3D

var Command : CanvasLayer
var GuardState : String = "None"
#var SceneManager : GameScenemanager
#var ScreenShake = 0.0
#var InUI: bool = false

#func _process(delta: float) -> void:
	#ScreenShake *= 0.9
