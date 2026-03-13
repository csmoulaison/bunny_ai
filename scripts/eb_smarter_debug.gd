extends Node

@export var eb: EbRoot
@export var label: Label
@export var target_mesh: MeshInstance3D

func _process(_dt: float):
	var brain: EbBrainSmarter = eb.get_node("BrainSmarter")
	target_mesh.position = brain.target
	
	var state_string = "State | "
	match brain.previous_action:
		EbBrainSmarter.Action.ROAM:
			state_string += "Roam"
		EbBrainSmarter.Action.LISTEN:
			state_string += "Listen"
		EbBrainSmarter.Action.SEARCH:
			state_string += "Search"
		EbBrainSmarter.Action.HUNT:
			state_string += "Hunt"
		EbBrainSmarter.Action.STUNNED:
			state_string += "Stunned"
	label.text = state_string
	
	label.text += "\nAlertness: %0.2f" % brain.alertness
