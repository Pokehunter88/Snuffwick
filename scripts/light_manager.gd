extends Node2D

var light_sources

func _ready() -> void:
	light_sources = get_tree().get_nodes_in_group("light_sources")
	
	print(light_sources)
	
