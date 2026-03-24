extends MeshInstance3D

@onready var search_node: SearchNode = get_parent() as SearchNode

func _process(_dt: float):
	var material = get_surface_override_material(0)
	material.albedo_color = Color(search_node.score, 0.0, 0.0)
	set_surface_override_material(0, material)
