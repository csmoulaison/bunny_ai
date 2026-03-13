extends Node

@export var eb: EbRoot
@export var camera: Camera3D

func _process(dt: float):
	camera.position = eb.position + Vector3(2.5, 2.5, 2.5)
	camera.look_at(eb.position + Vector3(0.0, 1.0, 0.0))
