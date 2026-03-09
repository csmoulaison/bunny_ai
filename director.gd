extends Node

signal set_eb_path(path: Node)

@export var starting_path: Node

func _ready():
	emit_signal("set_eb_path", starting_path)
