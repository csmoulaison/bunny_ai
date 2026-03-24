class_name SearchZone extends Node3D

@onready var area: Area3D = $Area
var search_nodes: Array[SearchNode]

func _ready():
	var tmp_nodes: Array[Node] = get_children()
	for node in tmp_nodes:
		if node is SearchNode:
			search_nodes.push_back(node)
