extends Node

@export var eb: EbRoot
@export var label: Label
@export var target_mesh: MeshInstance3D

func _process(_dt: float):
	var brain: EbBrainSmart = eb.get_node("BrainSmart")
	target_mesh.global_position = brain.target

	var state_string = "State | "
	match brain.state:
		EbBrainSmart.State.ROAM_MOVE:
			state_string += "Roam Move %0.2f" % brain.roam_move_listen_timer
		EbBrainSmart.State.ROAM_LISTEN:
			state_string += "Roam Listen %0.2f" % brain.roam_move_listen_timer
		EbBrainSmart.State.INVESTIGATE:
			state_string += "Investigate"
		EbBrainSmart.State.SEARCH:
			state_string += "Search over in %0.2f, " % brain.search_state_timer + "move in %0.2f" % brain.search_listen_timer
		EbBrainSmart.State.HUNT:
			state_string += "Hunt"
		EbBrainSmart.State.STUNNED:
			state_string += "Stunned %0.2f" % brain.stunned_timer
	label.text = state_string
