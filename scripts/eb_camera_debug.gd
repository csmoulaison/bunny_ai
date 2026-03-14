extends Node

@export var eb: EbRoot
@export var camera: Camera3D
@export var distance: float = 10.0

func _process(dt: float):
	camera.position = eb.position + Vector3(distance, distance * 3.0, distance)
	camera.look_at(eb.position + Vector3(0.0, 1.5, 0.0))
