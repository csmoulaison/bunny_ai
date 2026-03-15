extends Node

@export var bunny: Bunny
@export var camera: Camera3D
@export var camera_distance: float = 10.0
@export var nav_target_sphere: MeshInstance3D
@export var player_guess_sphere: MeshInstance3D
@export var explore_zone_box: MeshInstance3D
@export var guess_zone_box: MeshInstance3D

func _process(_dt: float):
	camera.global_position = bunny.global_position + Vector3(camera_distance, camera_distance * 3.0, camera_distance)
	camera.look_at(bunny.global_position + Vector3(0.0, 1.5, 0.0))
	
	nav_target_sphere.global_position = bunny.nav_target_position()
	nav_target_sphere.scale = Vector3(4.0, 4.0, 4.0)
	
	player_guess_sphere.global_position = bunny.player_guess_center
	var s = bunny.player_guess_radius * 2.0
	player_guess_sphere.scale = Vector3(s, s, s)
	var material = player_guess_sphere.get_surface_override_material(0)
	material.albedo_color = Color(0.0, 0.0, bunny.player_guess_intensity, lerp(0.15, 0.8, bunny.player_guess_intensity))
	player_guess_sphere.set_surface_override_material(0, material)

	var explore_zone_mesh = explore_zone_box.mesh
	var explore_shape_size = bunny.initial_explore_zones[0].area.get_node("CollisionShape3D").shape.size
	explore_zone_mesh.size = explore_shape_size
	explore_zone_box.global_position = bunny.initial_explore_zones[0].global_position
	
	if bunny.player_guess_zones.size() > 0:
		var guess_zone_mesh = guess_zone_box.mesh
		var guess_shape_size = bunny.player_guess_zones[0].area.get_node("CollisionShape3D").shape.size
		guess_zone_mesh.size = guess_shape_size
		guess_zone_box.global_position = bunny.player_guess_zones[0].global_position
