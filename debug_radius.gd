extends MeshInstance3D

@export var bunny: Node3D
@export var index: int

func _process(dt: float):
	var d = bunny.detection_radii[index] * 2.0
	scale = Vector3(d, d, d)
