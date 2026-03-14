class_name SearchNode extends Node3D

@export var debug_mesh: MeshInstance3D

var score: float = 0.0

func _process(_dt: float):
	var material = debug_mesh.get_surface_override_material(0)
	material.albedo_color = Color(score, 0.0, 0.0)
	debug_mesh.set_surface_override_material(0, material)
