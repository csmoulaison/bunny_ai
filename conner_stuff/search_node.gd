class_name SearchNode extends Node3D

@onready var debug_mesh: MeshInstance3D = $DebugSphere
@export var use_debug_sphere: bool = true

var score: float = 0.0

func _ready():
	if !use_debug_sphere:
		debug_mesh.queue_free()
