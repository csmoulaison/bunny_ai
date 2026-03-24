@tool
class_name SearchNodeGenerator 
extends EditorScript

@export var generation_radius: float = 1.25
@export var min_distance: float = 1.25
@export var max_iterations: int = 500
@export var max_depth: int = 100
@export var floor_height: float = 0.15
@export var max_nodes: int = 50

var root: Node
var navigation_map: RID
var guid: int = 0

const search_node_scene: PackedScene = preload("res://scenes/search_node.tscn")

func _run():
	root = EditorInterface.get_edited_scene_root()
	var zones_parent: Node = root.find_child("SearchZonesParent")
	var zones: Array[Node] = zones_parent.get_children()
	navigation_map = root.get_world_3d().get_navigation_map()
	if !navigation_map:
		print("SEARCH NODE GENERATION: Navigation map is not available. Make sure NavigationRegion is set up and baked.")
		return
	var count: int = 0
	for zone_node in zones:
		#if count > 0: break
		count += 1
		if zone_node is not SearchZone:
			print("SEARCH NODE GENERATION: Zone parent child is not SearchZone!")
			return
		var zone: SearchZone = zone_node as SearchZone
		
		for node in zone.get_children():
			if node is SearchNode:
				node.queue_free()
			
		var area: Area3D = zone.get_node("Area")
		if area == null:
			print("SEARCH NODE GENERATION: No Area in zone!")
			continue
		var shape_node = area.get_node("CollisionShape3D")
		if shape_node == null:
			print("SEARCH NODE GENERATION: No CollisionShape3D child!")
			return
		var shape_resource = shape_node.shape
		if shape_resource is not BoxShape3D:
			print("SEARCH NODE GENERATION: Shape resource is not box shape!")
			return
		var extents: Vector3 = shape_resource.size / 2.0
		new_node(Vector3(zone.global_position.x, floor_height, zone.global_position.z), zone, shape_node.global_position, extents, 0)

func new_node(center: Vector3, zone: SearchZone, col_pos: Vector3, extents: Vector3, depth: int):
	if depth > max_depth:
		print("max depth!")
		return
	for i in max_iterations:
		if i >= max_iterations - 2:
			print("max iterations!")
		var angle: float = randf() * 2.0 * PI
		var pos: Vector3 = center + Vector3(generation_radius * cos(angle), 0.0, generation_radius * sin(angle))
		pos.y = floor_height
		var bad_position: bool = false
		for existing_node in zone.get_children():
			if existing_node is not SearchNode:
				continue
			if pos.distance_to(existing_node.global_position) < min_distance:
				bad_position = true
				break
		if bad_position:
			continue
			
		if(pos.x < col_pos.x - extents.x
		|| pos.x > col_pos.x + extents.x
		|| pos.z < col_pos.z - extents.z
		|| pos.z > col_pos.z + extents.z):
			continue
			
		var closest_point_on_navmesh: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, pos)
		if pos.distance_to(closest_point_on_navmesh) > 0.01:
			continue

		var instance = search_node_scene.instantiate()
		instance.name = "generated_node_" + str(guid)
		guid += 1
		zone.add_child(instance)
		instance.global_position = pos
		instance.owner = root
		new_node(pos, zone, col_pos, extents, depth + 1)

""" Old logic
for i in max_iterations:
	if instance_count > max_nodes: 
		print("hit max nodes!")
		break

	var x: float = randf_range(area.global_position.x - extents.x, area.global_position.x + extents.x)
	var z: float = randf_range(area.global_position.z - extents.z, area.global_position.z + extents.z)
	var pos: Vector3 = Vector3(x, floor_height, z)

	var bad_position: bool = false
	for existing_node in zone.get_children():
		if existing_node is not SearchNode:
			continue
		if pos.distance_to(existing_node.global_position) < min_distance:
			bad_position = true
			break
	if bad_position:
		#print("Too close")
		continue

	var closest_point_on_navmesh: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, pos)
	#pos = closest_point_on_navmesh
	if pos.distance_to(closest_point_on_navmesh) > 0.01:
		#print("unsuitable position")
		continue
	else:
		pass
		#print("suitable position")
"""
