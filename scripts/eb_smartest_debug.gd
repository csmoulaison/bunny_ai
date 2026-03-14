extends Node

@export var eb: EbRoot
@export var player_guess_mesh: MeshInstance3D

var brain: EbBrainSmartest

func _ready():
	brain = eb.get_node("BrainSmartest")
	
func _process(_dt: float):
	player_guess_mesh.global_position = brain.player_guess_center
	var s = brain.player_guess_radius * 2.0
	player_guess_mesh.scale = Vector3(s, s, s)
	var material = player_guess_mesh.get_surface_override_material(0)
	material.albedo_color = Color(0.0, 0.0, brain.player_guess_intensity, clamp(brain.player_guess_intensity * 1.0, 0.2, 0.9))
	player_guess_mesh.set_surface_override_material(0, material)
