@tool
class_name SearchNodeGenerator 
extends EditorScript

@export var min_distance: float = 0.5
@export var iterations: int = 1000

func _run():
	var root: Node = EditorInterface.get_edited_scene_root()
	var zones_parent: Node = root.find_child("SearchZonesParent")
	var zones: Array[Node] = zones_parent.get_children()
	for zone in zones:	
		for node in zone.get_children():
			node.queue_free()
		for i in iterations:
			
			var x: float = zone.area
