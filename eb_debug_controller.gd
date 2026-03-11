extends Node

@export var eb: EbRoot
@export var camera: Camera3D
@export var label: Label
@export var target_mesh: MeshInstance3D

func _process(_dt: float):
	camera.position = eb.position + Vector3(2.5, 2.5, 2.5)
	camera.look_at(eb.position + Vector3(0.0, 1.0, 0.0))
	
	var brain: EbBrain = eb.get_node("Brain")
	target_mesh.position = brain.target
	
	var state_string = "State | "
	match brain.previous_action:
		EbBrain.Action.ROAM:
			state_string += "Roam"
		EbBrain.Action.LISTEN:
			state_string += "Listen"
		EbBrain.Action.SEARCH:
			state_string += "Search"
		EbBrain.Action.HUNT:
			state_string += "Hunt"
		EbBrain.Action.STUNNED:
			state_string += "Stunned"
	label.text = state_string
	
	label.text += "\nAlertness: %0.2f" % brain.alertness
